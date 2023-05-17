# frozen_string_literal: true

##
# Rails Job to submit a hold request to Folio for processing
class SubmitFolioRequestJob < ApplicationJob
  queue_as :default

  # we pass the ActiveRecord identifier to our job, rather than the ActiveRecord reference.
  #   This is recommended as a Sidekiq best practice (https://github.com/mperham/sidekiq/wiki/Best-Practices).
  #   It also helps reduce the size of the Redis database (used by Sidekiq), which stores its data in memory.
  def perform(request_id, _options = {})
    request = find_request(request_id)

    return true unless request

    Sidekiq.logger.info("Started SubmitFolioRequestJob for request #{request_id}")
    response = Command.new(request, **options).execute!

    Sidekiq.logger.debug("FOLIO response: #{response}")
    request.merge_ils_response_data(FolioResponse.new(response.with_indifferent_access))
    request.save
    request.send_approval_status!
    Sidekiq.logger.info("Completed SubmitFolioRequestJob for request #{request_id}")
  end

  def find_request(request_id)
    Request.find(request_id)
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify('Unable to find Request', conext: { request_id: request_id })
  end

  # Submit a hold request to FOLIO
  class Command
    attr_reader :request, :folio_client, :barcode

    delegate :user, to: :request
    delegate :patron, to: :user

    def initialize(request, folio_client: nil, barcode: nil)
      @request = request
      @folio_client = folio_client || FolioClient.new
      @barcode = barcode
    end

    def execute!
      {}
    end

    def request_params
      {}
    end
  end

  def self.command
    Command
  end
end
