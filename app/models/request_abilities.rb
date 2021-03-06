# frozen_string_literal: true

# Describe request types available for a given generic request
class RequestAbilities
  def self.rules
    @rules ||= {
      mediateable: LocationRules.new(Settings.mediateable),
      hold_recallable: LocationRules.new(Settings.hold_recallable),
      scannable: LocationRules.new(Settings.scannable)
    }
  end

  attr_reader :request

  # @param [Request] request
  def initialize(request)
    @request = request
  end

  def scannable?
    return false unless Settings.features.scan_service

    applicable_rules(:scannable).any?
  end

  # With covid-19 restrictions, some items were exclusively available for scanning
  def scannable_only?
    applicable_rules(:scannable).any?(&:only_scannable)
  end

  def mediateable?
    applicable_rules(:mediateable).any?
  end

  # returns a true if any of the following is true
  #   - The incoming request includes a barcode (which means an item-level link, likely a checked out item)
  #   - The home location or current location is an allowed recallable location by Settings.hold_recallable
  #   - There is only a single item to be requested and it is checked out
  def hold_recallable?
    return false unless Settings.features.hold_recall_service

    request.barcode_present? ||
      hold_recallable_location? ||
      single_checked_out_item?
  end

  def pageable?
    !mediateable? && !hold_recallable?
  end

  private

  def hold_recallable_location?
    applicable_rules(:hold_recallable).any?
  end

  def single_checked_out_item?
    request.holdings_object.single_checked_out_item?
  end

  def applicable_rules(request_type)
    self.class.rules[request_type].applies_to(request)
  end
end
