# frozen_string_literal: true

##
# Rails Job to enqueue request cache warmups for every user attached to any Aeon activity.
class WarmupAeonActivitiesJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform
    usernames = aeon_client.activities.flat_map(&:users).map(&:username).uniq
    usernames.each_with_index do |username, index|
      WarmupAeonRequestsJob.set(wait: (index * 5).seconds).perform_later(username)
    end
  end

  delegate :aeon_client, to: :Current
end
