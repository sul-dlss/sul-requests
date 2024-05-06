# frozen_string_literal: true

##
# Helpers for formatting and displaying pickup libraries
module PickupLibrariesHelper
  def label_for_pickup_destinations_dropdown(pickup_destinations)
    if pickup_destinations.many?
      'Deliver to'
    else
      'Will be delivered to'
    end
  end

  # Get the label, if it exists, for the pickup destination
  def destination_label(pickup_destination)
    Settings.ils.pickup_destination_class.constantize.new(pickup_destination).display_label || pickup_destination
  end

  private

  # Return the array of destinations for the dropdown
  def pickup_destinations_array(pickup_destinations)
    pickup_destinations.map do |k|
      [destination_label(k) || k, k]
    end.sort
  end
end
