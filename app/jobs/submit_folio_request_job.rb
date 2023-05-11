# frozen_string_literal: true

##
# Rails Job to submit a hold request to Folio for processing
class SubmitFolioRequestJob < ApplicationJob
  queue_as :default

  # we pass the ActiveRecord identifier to our job, rather than the ActiveRecord reference.
  #   This is recommended as a Sidekiq best practice (https://github.com/mperham/sidekiq/wiki/Best-Practices).
  #   It also helps reduce the size of the Redis database (used by Sidekiq), which stores its data in memory.
  def perform(request_id, _options = {})
    return true unless enabled?

    request = find_request(request_id)

    return true unless request

    # TODO: something like this
    # response = Call folio here
    # request.merge_folio_response_data(FolioResponse.new(response.with_indifferent_access))
    # request.save
    # request.send_approval_status!
    logger.info("NOOP FolioRequest request #{request_id}")
  end

  def find_request(request_id)
    Request.find(request_id)
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify('Unable to find Request', conext: { request_id: request_id })
  end
end
