# frozen_string_literal: true

##
# Rails Job to refresh the cached Aeon requests for a single user.
class WarmupAeonRequestsJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(username)
    aeon_client.warmup_requests_for(username:)
  end

  delegate :aeon_client, to: :Current
end
