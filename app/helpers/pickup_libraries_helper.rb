# frozen_string_literal: true

##
# Helpers for formatting and displaying pickup libraries
module PickupLibrariesHelper
  # Pickup libraries for FOLIO or Symphony
  def select_for_pickup_destinations(form)
    pickup_destinations = form.object.pickup_destinations
    return unless pickup_destinations.present?

    select_for_multiple_destinations(form, pickup_destinations) || single_destination_markup(form, pickup_destinations.first)
  end

  def label_for_pickup_destinations_dropdown(pickup_destinations)
    if pickup_destinations.many?
      'Deliver to'
    else
      'Will be delivered to'
    end
  end

  private

  # Symphony
  def select_for_multiple_destinations(form, pickup_destinations)
    return unless pickup_destinations.length > 1

    form.select(
      :destination,
      pickup_destinations_array(pickup_destinations),
      {
        label: label_for_pickup_destinations_dropdown(pickup_destinations),
        selected: form.object.destination || form.object.default_pickup_destination
      },
      aria: { controls: 'scheduler-text' },
      data: { 'paging-schedule-updater' => 'true', 'text-selector' => "[data-text-object='#{form.object.object_id}']" }
    )
  end

  def single_destination_markup(form, pickup_destination)
    destination_label = destination_label(pickup_destination)
    <<-HTML
      <div class='form-group'>
        <div class='#{label_column_class} control-label'>
          #{label_for_pickup_destinations_dropdown([])}
        </div>
        <div class='#{content_column_class} input-like-text'>
          #{destination_label}
        </div>
        #{form.hidden_field :destination, value: pickup_destination}
      </div>
    HTML
  end

  # Get the label, if it exists, for the pickup destination
  def destination_label(pickup_destination)
    Settings.ils.pickup_destination_class.constantize.new(pickup_destination).display_label || pickup_destination
  end

  # Return the array of destinations for the dropdown
  def pickup_destinations_array(pickup_destinations)
    pickup_destinations.map do |k|
      [destination_label(k) || k, k]
    end.sort
  end
end
