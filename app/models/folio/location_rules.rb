# frozen_string_literal: true

module Folio
  # Container for location rules defined on FOLIO locations
  class LocationRules
    include Enumerable

    delegate :each, to: :rules

    attr_reader :rules

    # Rules organized by request type, used in RequestAbilities
    def self.rules_by_request_type(rules = nil)
      location_rules = new(rules)
      {
        pageable: location_rules.paging_rules,
        scannable: location_rules.scanning_rules,
        hold_recallable: [] # not handled at location level in FOLIO
      }
    end

    # Fallback rules used when no other rules apply
    def self.fallback_rules
      [fallback_paging_rule, fallback_scanning_rule]
    end

    # A generic location that matches any request
    def self.fallback_location
      Folio::Location.new(id: nil, code: '*', name: 'fallback')
    end

    # A generic paging rule that matches any request
    def self.fallback_paging_rule
      PagingRule.new(
        fallback_location,
        service_points: [{ code: Settings.default_pickup_library }]
      )
    end

    # A generic scanning rule that matches any request
    def self.fallback_scanning_rule
      ScanningRule.new(
        fallback_location,
        service_point: { code: Settings.default_scan_destination.key },
        pseudopatron_barcode: Settings.default_scan_destination.patron_barcode
      )
    end

    # Fetch all location rules from FOLIO, or provide a list of rules
    def initialize(rules = nil, client: FolioClient.new)
      @client = client
      @rules = rules || default_rules
    end

    # Selects the rules that apply to a given request
    def applies_to(request)
      lazy.select { |rule| rule.applies_to?(request) }
    end

    # All rules that apply to paging requests
    def paging_rules
      lazy.select { |rule| rule.is_a? PagingRule }
    end

    # All rules that apply to scanning requests
    def scanning_rules
      lazy.select { |rule| rule.is_a? ScanningRule }
    end

    private

    # List of service points that should be default options for pickup
    def default_pickup_locations
      @client.service_points.select(&:default_pickup_location)
    end

    # All rules configured in FOLIO, plus the fallback rules
    def default_rules
      @client.locations.flat_map(&:rules).compact + LocationRules.fallback_rules
    end

    # Generic rule for requests at a given location
    class Rule
      attr_reader :location

      # Create a rule using extra data stored on a Location
      # @param [Folio::Location] location
      def initialize(location, send_honeybadger_notice_if_used: false)
        @location = location
        @send_honeybadger_notice_if_used = send_honeybadger_notice_if_used
      end

      # Test if the rule would apply to the given request
      # @param [Request] request
      def applies_to?(request)
        return true if @location.code == '*'

        @location.code.match? request.library_location.folio_location_code
      end

      # TODO: remove and rename after FOLIO migration is complete
      # this name is confusing because .match? is supposed to be for regex
      alias match? applies_to?
    end

    # Rule governing how page requests are handled at a given location
    class PagingRule < Rule
      attr_reader :mediation_group_key, :aeon_site

      def initialize(location, aeon_site: nil, mediation_group_key: nil, service_points: [], **kwargs)
        super(location, **kwargs)
        @aeon_site = aeon_site
        @mediation_group_key = mediation_group_key
        @service_points = service_points
      end

      def aeon?
        @aeon_site.present?
      end

      def mediated?
        @mediation_group_key.present?
      end

      def pickup_libraries
        service_points.map(&:code)
      end

      private

      def service_points
        @service_points.map { |sp| Folio::ServicePoint.new(sp) }
      end

      # TODO: find service points that are in the same library as the requested item, which should always be valid pickup locations
      def local_service_points
        []
      end
    end

    # Rule governing how scan requests are handled at a given location
    class ScanningRule < Rule
      attr_reader :pseudopatron_barcode

      MaterialType = Struct.new('MaterialType', :id, :name)

      def initialize(location, pseudopatron_barcode: nil, material_types: [], service_point: nil, **kwargs)
        super(location, **kwargs)
        @pseudopatron_barcode = pseudopatron_barcode
        @material_types = material_types
        @service_point = service_point
      end

      def destination
        service_point.code
      end

      def service_point
        Folio::ServicePoint.new(@service_point)
      end

      def material_types
        @material_types.map { |mt| MaterialType.new(mt) }
      end
    end
  end
end
