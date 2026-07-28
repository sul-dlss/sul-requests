# frozen_string_literal: true

# Alert with a leading icon. Pass a type (:info, :success, :warning).
class AlertComponent < ViewComponent::Base
  ICONS = {
    info: 'bi-info-circle-fill',
    success: 'bi-check-circle-fill',
    warning: 'bi-exclamation-triangle-fill'
  }.freeze

  ALERTS = {
    info: 'alert-info',
    success: 'alert-success',
    warning: 'alert-warning'
  }.freeze

  def initialize(type:, dismissable: false, classes: [], icon_classes: [], with_icon: true)
    @type = type
    @dismissable = dismissable
    @classes = Array(classes)
    @icon_classes = Array(icon_classes)
    @with_icon = with_icon
  end

  attr_reader :type, :with_icon

  def dismissable?
    @dismissable
  end

  def classes
    alert_classes + @classes
  end

  def icon_class
    "bi #{ICONS.fetch(type)} #{@icon_classes&.join(' ')}"
  end

  def alert_classes
    ['alert', ALERTS.fetch(type).to_s]
  end

  def aria_label
    "#{type.to_s.capitalize} icon"
  end
end
