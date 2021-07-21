# frozen_string_literal: true

###
#  Mixin to encapsulate defining if a request should be a mediated page
###
module Mediateable
  def mediateable?
    mediateable_rules.applies_to(self).any?
  end

  def mediateable_rules
    LocationRules.new(Settings.mediateable)
  end
end
