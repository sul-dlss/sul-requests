# frozen_string_literal: true

# Describe request types available for a given generic request
class RequestAbilities
  def self.rules
    @rules ||= location_rules_class.rules_by_request_type
  end

  class_attribute :location_rules_class, default: Settings.ils.location_rules&.constantize || LocationRules

  attr_reader :request

  # @param [Request] request
  def initialize(request)
    @request = request
  end

  def scannable?
    return false unless Settings.features.scan_service

    scanning_rule.present?
  end

  # With covid-19 restrictions, some items were exclusively available for scanning
  def scannable_only?
    scanning_rule&.only_scannable
  end

  def mediateable?
    paging_rule&.mediated? || aeon_pageable?
  end

  def aeon_pageable?
    paging_rule&.aeon?
  end

  def aeon_site
    paging_rule&.aeon_site if aeon_pageable?
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
    !mediateable? && !hold_recallable? && paging_rule.present?
  end

  def paging_rule
    @paging_rule ||= applicable_rules(:pageable).first
  end

  def scanning_rule
    @scanning_rule ||= applicable_rules(:scannable).first
  end

  private

  def all_items_hold_recallable?
    request.holdings_object.any? && request.holdings_object.all?(&:hold_recallable?)
  end

  def applicable_rules(request_type)
    self.class.rules[request_type].applies_to(request)
  end
end
