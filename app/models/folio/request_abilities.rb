# frozen_string_literal: true

module Folio
  # Describe request types available for a given generic request
  class RequestAbilities
    attr_reader :request

    include Folio::TypesUtils

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
        service_point = request.holdings.filter_map { |item| item.effective_location.details['scanServicePointCode'] }.first

        Settings.scan_destinations[service_point || :default] || Settings.scan_destinations.default
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
      request.holdings.any? { |item| item.effective_location.details['pageAeonSite'] }
    end

    def aeon_site
      request.holdings.filter_map { |item| item.effective_location.details['pageAeonSite'] }.first || aeon_site_for_origin
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

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def default_pickup_destination
      return 'EAST-ASIA' if request.origin_location&.match?(Regexp.union(/^EAL-SETS$/, /^EAL-STKS-/))

      # Find service point which is default for this particular campus
      pickup = Folio::Types.instance.service_points.select do |_k, v|
        v.is_default_for_campus.present? && v.is_default_for_campus == request.holdings.first&.effective_location&.campus&.code
      end.values.map(&:code)
      pickup.present? ? pickup[0] : Settings.folio.default_service_point
    end

    private

    # Returns default service point codes
    def default_pickup_service_points
      Folio::Types.instance.service_points.select { |_k, v| v.is_default_pickup }.values.map(&:code)
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def additional_pickup_service_points
      # Map library to a service point
      service_point_code = map_to_service_point(request.origin)
      service_point_code.nil? ? [] : [service_point_code]
    end

    # Retrieve the service points associated with specific locations
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
