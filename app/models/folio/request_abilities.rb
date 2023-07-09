# frozen_string_literal: true

# Describe request types available for a given generic request
module Folio
  class RequestAbilities
    attr_reader :request

    # @param [Request] request
    def initialize(request)
      @request = request
    end

    def scannable?
      false
    end

    def scan_destination
      {}
    end

    # With covid-19 restrictions, some items were exclusively available for scanning
    def scannable_only?
      false
    end

    def mediateable?
      request.holdings.any? { |item| item.effective_location.details['pageMediationGroupKey'] } || aeon_pageable?
    end

    def aeon_pageable?
      request.holdings.any? { |item| item.effective_location.details['pageAeonSite'] }
    end

    def aeon_site
      request.holdings.map { |item| item.effective_location.details['pageAeonSite'] }.compact.first
    end

    # returns a true if any of the following is true
    #   - The incoming request includes a barcode (which means an item-level link, likely a checked out item)
    #   - All items in the holdings are hold/recallable, e.g. checked out, on order, in transit, etc.
    def hold_recallable?
      return false unless Settings.features.hold_recall_service

      request.barcode_present? ||
        all_items_hold_recallable?
    end

    def pageable?
      !mediateable? && !hold_recallable? && any_holdings_pageable?
    end

    def default_pickup_library
      nil
    end

    def pickup_libraries
      restricted_service_point_codes = request.holdings.flat_map { |item| item.effective_location.details.dig('pageServicePoints', 'code') }.compact.uniq
      return Settings.default_pickup_libraries if restricted_service_point_codes.empty?

      Settings.libraries.keys.select { |key| restricted_service_point_codes.include? Settings.libraries[key].folio_pickup_service_point_code }
    end

    private

    def all_items_hold_recallable?
      request.holdings.any? && request.holdings.all?(&:hold_recallable?) && request.holdings.all? do |item|
        types = circulation_rules.item_request_policy(item)&.dig('requestTypes') || []
        types.include?('Hold') || types.include?('Recall')
      end
    end

    def any_holdings_pageable?
      request.holdings.any? { |item| circulation_rules.item_request_policy(item)&.dig('requestTypes')&.include? 'Page' }
    end

    def circulation_rules
      Folio::CirculationRules::PolicyService.instance
    end
  end
end
