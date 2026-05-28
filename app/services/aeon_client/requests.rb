# frozen_string_literal: true

class AeonClient
  # Request handling for Aeon Client
  module Requests
    extend ActiveSupport::Concern

    def requests_for(username:)
      merged = merge_request_responses(
        all: cached_all_raw_requests_for(username:),
        active: raw_requests_for(username:, active_only: true)
      )
      merged.map { |data| Aeon::Request.from_dynamic(data) }
    end

    def warmup_requests_for(username:)
      cached_all_raw_requests_for(username:, force: true)
    end

    private

    def raw_requests_for(username:, active_only: false)
      response = get("Users/#{CGI.escape(username)}/requests", params: { activeOnly: active_only })

      handle_response(response, as_class: nil, not_found: [])
    end

    # Aeon requests are not deleted after completion, they only accumulate.
    # Fetching all requests (active_only: false) can take 10+s for power users.
    # Our notion of "active" requests deviates from Aeon's, but in ways where we can accept some staleness:
    # - We persist digitization requests as "active" for a period of time after delivery
    # - We consider "Awaiting Future Request Processing" as an active state, Aeon does not
    def cached_all_raw_requests_for(username:, force: false)
      Rails.cache.fetch("aeon/users/#{username}/requests", expires_in: 4.hours, force:) do
        raw_requests_for(username:, active_only: false)
      end
    end

    def merge_request_responses(all:, active:)
      all.index_by { |r| r['transactionNumber'] }
         .merge(active.index_by { |r| r['transactionNumber'] })
         .values
    end
  end
end
