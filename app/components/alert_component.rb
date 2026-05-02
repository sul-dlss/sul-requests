# frozen_string_literal: true

# Alert with a leading icon. Pass a type (:info, :success, :warning).
class AlertComponent < ViewComponent::Base
  ICONS = {
    info: 'info-circle-fill',
    success: 'check-circle-fill',
    warning: 'exclamation-triangle-fill'
  }.freeze

  def initialize(type:)
    @type = type
  end

  attr_reader :type

  def icon_class
    "bi bi-#{ICONS.fetch(type)}"
  end

  def aria_label
    "#{type.to_s.capitalize} icon"
  end
end
