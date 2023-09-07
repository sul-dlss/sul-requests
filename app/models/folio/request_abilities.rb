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
        service_point = request.holdings.filter_map { |item| item.permanent_location.details['scanServicePointCode'] }.first

        Settings.scan_destinations[service_point || :default] || Settings.scan_destinations.default
      end
    end

    # With covid-19 restrictions, some items were exclusively available for scanning
    def scannable_only?
      return false unless scannable?

      !(mediateable? || pageable? || hold_recallable?)
    end

    def mediateable?
      request.holdings.any? { |item| item.permanent_location.details['pageMediationGroupKey'] } || aeon_pageable?
    end

    def aeon_pageable?
      request.holdings.any? { |item| item.permanent_location.details['pageAeonSite'] }
    end

    def aeon_site
      request.holdings.filter_map { |item| item.permanent_location.details['pageAeonSite'] }.first
    end

    # returns a true if any of the following is true
    #   - The incoming request includes a barcode (which means an item-level link, likely a checked out item)
    #   - All items in the holdings are hold/recallable, e.g. checked out, on order, in transit, etc.
    def hold_recallable?
      return false unless Settings.features.hold_recall_service

      request.barcode_present? ||
        all_items_hold_recallable? ||
        request.all_holdings.none?
    end

    def pageable?
      !mediateable? && !hold_recallable? && any_holdings_pageable?
    end

    # FOLIO
    def pickup_destinations
      return (default_pickup_service_points + additional_pickup_service_points).uniq if location_restricted_service_point_codes.empty?

      location_restricted_service_point_codes
    end

    # Find service point which is default for this particular campus
    def default_pickup_destination
      campus_code = request.holdings.first&.permanent_location&.campus&.code
      service_points = if campus_code
                         Folio::Types.service_points.where(is_default_for_campus: campus_code).map(&:code)
                       else
                         []
                       end
      service_points.first || Settings.folio.default_service_point
    end

    private

    # Returns default service point codes
    def default_pickup_service_points
      Folio::Types.service_points.where(is_default_pickup: true).map(&:code)
    end

    def additional_pickup_service_points
      # Find library id for the library with this code
      library = Folio::Types.libraries.find_by(code: request.origin)
      return [] unless library

      service_point_code = library.primary_service_points.find { |sp| sp.pickup_location? && !sp.is_default_pickup }&.code
      Array(service_point_code)
    end

    # Retrieve the service points associated with specific locations
    def location_restricted_service_point_codes
      request.holdings.flat_map do |item|
        Array(item.permanent_location.details['pageServicePoints']).pluck('code')
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
