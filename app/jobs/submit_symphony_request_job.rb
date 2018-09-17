##
# Rails Job to submit a Scan request to Symphony for processing
class SubmitSymphonyRequestJob < ActiveJob::Base
  queue_as :default

  # we pass the ActiveRecord identifier to our job, rather than the ActiveRecord reference.
  #   This is recommended as a Sidekiq best practice (https://github.com/mperham/sidekiq/wiki/Best-Practices).
  #   It also helps reduce the size of the Redis database (used by Sidekiq), which stores its data in memory.
  def perform(request_id, options = {})
    return true unless enabled?

    request = find_request(request_id)

    return true unless request

    Sidekiq::Logging.logger.info("Started SubmitSymphonyRequestJob for request #{request_id}")
    response = Command.new(request, options).execute!

    Sidekiq::Logging.logger.debug("Symphony response string: #{response}")
    request.merge_symphony_response_data(response.with_indifferent_access)
    request.save
    request.send_approval_status!
    Sidekiq::Logging.logger.info("Completed SubmitSymphonyRequestJob for request #{request_id}")
  end

  def find_request(request_id)
    request = begin
      Request.find(request_id)
    rescue ActiveRecord::RecordNotFound
      Honeybadger.notify(
        "Attempted to call Symphony for Request with ID #{request_id}, but no such Request was found."
      )
    end
    request
  end

  def enabled?
    Settings.symphony_api.enabled && Settings.symphony_api.url.present?
  end

  ##
  # Command to submit a Scan request to Symphony for processing
  class Command
    include ActiveSupport::Benchmarkable

    attr_reader :request, :options

    delegate :user, to: :request

    def initialize(request, options = {})
      @request = request
      @options = options
    end

    def execute!
      benchmark "Sending func_request_webservice_new.make_request with #{request_params.inspect}" do
        response = client.get('func_request_webservice_new.make_request', request_params)
        JSON.parse(response.body)['request_response'] || {}
      end
    end

    def request_params
      # NOTE:  any changes to params (new ones, key name changes) must be coordinated with
      # Symphony programmers
      patron_from_request.merge(items_from_request).merge(
        req_type: req_type
      ).reject { |_, v| v.blank? }
    end

    private

    def req_type
      case request
      when Scan
        'SCAN'
      when HoldRecall
        'HOLD'
      when Page, MediatedPage
        'PAGE'
      end
    end

    # rubocop:disable Metrics/AbcSize
    def patron_from_request
      {
        sunet_id: (user.webauth if user.webauth_user?),
        library_id: user.library_id,
        patron_name: (user.name if user.library_id.blank?),
        patron_email: (user.email_address if user.library_id.blank?),
        proxy_group: (user.proxy_access.name if request.proxy?)
      }
    end

    def items_from_request
      {
        ckey: request.item_id,
        items: barcodes.join('^') + '^',
        copy_note: (copy_notes.join('^') + '^' if copy_notes.present?),
        home_lib: request.origin,
        item_comments: request.item_comment,
        req_comment: request.request_comment,
        requested_date: request.created_at.strftime('%m/%d/%Y'),
        pickup_lib: (request.destination unless request.is_a? Scan),
        not_needed_after: (request.needed_date.strftime('%m/%d/%Y') if request.needed_date)
      }
    end
    # rubocop:enable Metrics/AbcSize

    def barcodes
      items = options[:barcodes]
      items ||= request.barcodes.reject(&:blank?)
      items = ['NO_ITEMS'] if items.blank?
      items
    end

    def copy_notes
      return if request.public_notes.blank?

      result = []
      request.public_notes.each do |barcode, note|
        result << "#{barcode}:#{note}" if barcodes.include? barcode
      end
      result
    end

    def client
      @client ||= Faraday.new(url: base_url)
    end

    def base_url
      Settings.symphony_api.url
    end

    def logger
      Rails.logger
    end
  end
end
