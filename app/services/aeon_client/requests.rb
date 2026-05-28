# frozen_string_literal: true

class AeonClient
  # Request handling for Aeon Client
  module Requests
    extend ActiveSupport::Concern

    # Submit a new request to Aeon
    # @param aeon_payload [AeonClient::RequestData]
    def create_request(aeon_payload)
      response = post('Requests/create', aeon_payload.as_json.compact)

      handle_response(response, as_class: Aeon::Request)
    end

    # Submit a request patch to Aeon
    # @param aeon_payload [AeonClient::RequestData]
    def update_request(transaction_number:, aeon_payload:)
      response = patch("Requests/#{transaction_number}", aeon_payload)

      handle_response(response, as_class: Aeon::Request)
    end

    def update_request_route(transaction_number:, status:)
      response = post("Requests/#{transaction_number}/route", { newStatus: status })

      handle_response(response, as_class: Aeon::Request)
    end

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

    RequestData = Data.define(:call_number, :document_type, :ead_number, :for_publication, :format,
                              :item_author, :item_citation, :item_date, :item_info1, :item_info2, :appointment_id,
                              :item_info3, :item_info4, :item_info5, :item_number, :item_subtitle, :item_title, :item_volume,
                              :location, :web_request_form, :activity_id,
                              :reference_number, :shipping_option, :site, :special_request, :system_id, :username) do
      def omission = '…'

      def as_json # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        {
          appointmentId: appointment_id&.to_i,
          callNumber: call_number&.truncate(255, omission:),
          eadNumber: ead_number&.truncate(255, omission:),
          forPublication: for_publication,
          format: format&.truncate(255, omission:),
          itemAuthor: item_author&.truncate(255, omission:),
          itemCitation: item_citation&.truncate(255, omission:),
          itemDate: item_date&.truncate(50, omission:),
          itemInfo1: item_info1&.truncate(255, omission:),
          itemInfo2: item_info2&.truncate(255, omission:),
          itemInfo3: item_info3&.truncate(255, omission:),
          itemInfo4: item_info4&.truncate(255, omission:),
          itemInfo5: item_info5&.truncate(255, omission:),
          itemNumber: item_number&.truncate(50, omission:),
          itemSubTitle: item_subtitle&.truncate(255, omission:),
          itemTitle: item_title&.truncate(255, omission:),
          itemVolume: item_volume&.truncate(255, omission:),
          location: location&.truncate(255, omission:),
          referenceNumber: reference_number&.truncate(50, omission:),
          shippingOption: shipping_option&.truncate(255, omission:),
          site: site,
          specialRequest: special_request&.truncate(255, omission:),
          system_id: system_id,
          username: username&.truncate(50, omission:),
          webRequestForm: web_request_form&.truncate(100, omission:) || 'SUL Requests',
          requestFor: request_for
        }.reject { |_k, v| v == UNSET }
      end

      def request_for
        return nil if activity_id.nil?
        return UNSET if activity_id.blank? || activity_id == UNSET

        { type: 'Activity', reference: activity_id }
      end

      def as_patch_json
        as_json.except(:webRequestForm).map do |k, v|
          if v.nil?
            { op: 'remove', path: "/#{k}" }
          else
            { op: 'replace', path: "/#{k}", value: v }
          end
        end
      end

      def self.with_defaults
        new(**members.index_with(UNSET), web_request_form: 'SUL Requests')
      end
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
