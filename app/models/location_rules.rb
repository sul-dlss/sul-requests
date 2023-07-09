# frozen_string_literal: true

# Mixin for parsing and checking location rules defined in YAML
class LocationRules
  include Enumerable

  attr_reader :rules

  # @param [Config::Option] rules (see `Rule` class for rule data)
  def initialize(rules)
    @rules = rules
  end

  def each
    rules.each do |rule|
      yield LocationRules::Rule.new(rule)
    end
  end

  # Selects the rules that apply to a given request
  # @param [Request] request
  def applies_to(request)
    lazy.select { |rule| rule.match?(request) }
  end

  # Utility for testing location rules against the request
  class Rule
    attr_reader :rule

    delegate :library, # single-valued library code
             :locations, # multi-valued list of location codes
             :locations_match, # multi-valued list of regular expression patterns to match against the request's origin_location
             :current_locations, # multi-valued list of location codes to match against the holding's current_location
             :item_types, # multi-valued list of item type codes
             :only_scannable, # with covid-19 restrictions, some items were exclusively scannable
             :default_pickup_library,
             :mediated,
             :aeon,
             :aeon_site,
             :destination,
             :send_honeybadger_notice_if_used,
             to: :rule

    # @param [Config::Option] rule
    def initialize(rule)
      @rule = rule
    end

    # Test if the rule would apply to the given request
    # @param [Request] request
    def match?(request)
      match_library?(request) &&
        match_location?(request) &&
        match_current_location?(request) &&
        match_types?(request)
    end

    def pickup_libraries
      (rule.pickup_libraries || Settings.default_pickup_libraries) + (rule.additional_pickup_libraries || [])
    end

    private

    def match_library?(request)
      library.nil? || Array(library).include?(request.origin)
    end

    def match_location?(request)
      (locations.nil? || Array(locations).include?(request.origin_location)) &&
        (locations_match.nil? || Array(locations_match).any? { |pattern| Regexp.new(pattern).match? request.origin_location })
    end

    def match_current_location?(request)
      return true if current_locations.nil?

      holding_current_locations = request.holdings.map do |holding|
        holding.try(:current_location).try(:code)
      end

      return false unless holding_current_locations.any?

      holding_current_locations.all? do |current_location|
        Array(current_locations).include?(current_location)
      end
    end

    def match_types?(request)
      return true if item_types.nil?

      holding_item_types = request.holdings.map(&:type)
      Array(item_types).intersect?(holding_item_types)
    end
  end
end
