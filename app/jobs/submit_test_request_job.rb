# frozen_string_literal: true

##
# Rails Job for testing submitting a hold request to an ILS for processing
class SubmitTestRequestJob < ApplicationJob
  queue_as :default

  # we pass the ActiveRecord identifier to our job, rather than the ActiveRecord reference.
  #   This is recommended as a Sidekiq best practice (https://github.com/mperham/sidekiq/wiki/Best-Practices).
  #   It also helps reduce the size of the Redis database (used by Sidekiq), which stores its data in memory.
  def perform(request_id, _options = {})
    find_request(request_id)

    logger.info("NOOP TestRequestJob request #{request_id}")
  end

  def find_request(request_id)
    Request.find(request_id)
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify('Unable to find Request', conext: { request_id: })
  end

  def self.command
    SubmitSymphonyRequestJob::SymWsCommand
  end
end
