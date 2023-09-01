# frozen_string_literal: true

# Draws the select a destionation widget
class DestinationSelectorComponent < ViewComponent::Base
  def initialize(form:)
    @form = form
  end

  attr_reader :form

  def request
    form.object
  end

  delegate :pickup_destinations, to: :request

  # Get the label, if it exists, for the pickup destination
  def destination_label(pickup_destination)
    Settings.ils.pickup_destination_class.constantize.new(pickup_destination).display_label || pickup_destination
  end

  # Return the array of destinations for the dropdown
  def pickup_destinations_array(pickup_destinations)
    pickup_destinations.map do |k|
      [destination_label(k), k]
    end.sort
  end
end
