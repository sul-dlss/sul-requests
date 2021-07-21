# frozen_string_literal: true

###
#  Mixin to encapsulate defining if a request is scannable
###
module Scannable
  def scannable?
    return false unless Settings.features.scan_service

    scannable_rules.applies_to(self).any?
  end

  def scannable_only?
    scannable_rules.applies_to(self).any?(&:only_scannable)
  end

  def scannable_rules
    LocationRules.new(Settings.scannable)
  end
end
