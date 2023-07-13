# frozen_string_literal: true

module Folio
  # Describe request types available for a given generic request
  class RequestAbilities
    attr_reader :request

    # @param [Request] request
    def initialize(request)
      @request = request
    end

    def scannable?
      scan_destination.present? && scannable_material_type?
    end

    def scannable_material_type?
      request.holdings.all? { |item| scan_destination.material_types.include?(item.material_type.name) }
    end

    def scan_destination
      @scan_destination ||= begin
        service_point = request.holdings.map { |item| item.effective_location.details['scanServicePoints'] }.flatten.first

        Settings.scan_destinations[service_point&.dig('code') || :default] || Settings.scan_destinations.default
      end
    end

    # With covid-19 restrictions, some items were exclusively available for scanning
    def scannable_only?
      return false unless scannable?

      !(mediateable? || pageable?)
    end

    def mediateable?
      request.holdings.any? { |item| item.effective_location.details['pageMediationGroupKey'] } || aeon_pageable?
    end

    def aeon_pageable?
      request.holdings.any? { |item| item.effective_location.details['pageAeonSite'] } || aeon_pageable_origin?
    end

    def aeon_pageable_origin?
      request.origin == 'SPEC-COLL'
    end

    def aeon_site
      request.holdings.filter_map { |item| item.effective_location.details['pageAeonSite'] }.first || aeon_site_for_origin
    end

    def aeon_site_for_origin
      case request.origin
      when 'SPEC-COLL'
        'SPECUA'
      end
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
      Settings.default_pickup_library
    end

    def pickup_libraries
      return default_pickup_libraries if location_restricted_service_point_codes.empty?

      Settings.libraries.keys.select do |key|
        location_restricted_service_point_codes.include? Settings.libraries[key].folio_pickup_service_point_code
      end.map(&:to_s)
    end

    def default_pickup_libraries
      libraries = Settings.default_pickup_libraries
      libraries + additional_pickup_libraries
    end

    def additional_pickup_libraries
      return ['MEDIA-MTXT'] if request.holdings.all? { |item| item.effective_location.library.code == 'MEDIA-CENTER' }

      []
    end

    private

    def location_restricted_service_point_codes
      request.holdings.flat_map do |item|
        Array(item.effective_location.details['pageServicePoints']).pluck('code')
      end.compact.uniq
    end

    def all_items_hold_recallable?
      return false unless request.holdings.any?
      return false unless request.holdings.all?(&:hold_recallable?)

      request.holdings.all? do |item|
        types = item_request_policy(item)
        types.include?('Hold') || types.include?('Recall')
      end
    end

    def item_request_policy(item)
      circulation_rules.item_request_policy(item)&.dig('requestTypes') || []
    end

    def any_holdings_pageable?
      request.holdings.any? { |item| circulation_rules.item_request_policy(item)&.dig('requestTypes')&.include? 'Page' }
    end

    def circulation_rules
      Folio::CirculationRules::PolicyService.instance
    end
  end
end
