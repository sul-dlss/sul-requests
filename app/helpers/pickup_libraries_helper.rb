# frozen_string_literal: true

##
# Helpers for formatting and displaying pickup libraries
module PickupLibrariesHelper
  include Folio::TypesUtils
  # Pickup libraries for Symphony
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
    destination_label = get_destination_label(pickup_destination)
    <<-HTML
      <div class='form-group'>
        <div class='#{label_column_class} control-label'>
          #{label_for_pickup_destinations_dropdown([])}
        </div>
        <div class='#{content_column_class} input-like-text'>
          #{destination_label || pickup_destination}
        </div>
        #{form.hidden_field :destination, value: pickup_destination}
      </div>
    HTML
  end

  # Get the label, if it exists, for the pickup destination
  def get_destination_label(pickup_destination)
    # If FOLIO, get the service point name
    return get_service_point_name(pickup_destination) if Settings.ils.bib_model == 'Folio::Instance'

    # If not FOLIO
    Settings.libraries[pickup_destination]&.label
  end

  # Return the array of destinations for the dropdown
  def pickup_destinations_array(pickup_destinations)
    # If FOLIO
    return pickup_service_points_array(pickup_destinations) if Settings.ils.bib_model == 'Folio::Instance'

    pickup_libraries_array(pickup_destinations)
  end

  # FOLIO version
  # Given an array of service point codes
  def pickup_service_points_array(pickup_service_points)
    # We want an array of arrays, with first element being label, second being code
    # First create hash by service point code to enable easier lookup
    service_points_hash = {}
    Folio::Types.instance.service_points.each_value do |service_point|
      service_points_hash[service_point.code] = service_point
    end
    pickup_service_points.map do |code|
      sp = service_points_hash[code]
      [sp.name, code]
    end
  end

  # Symphony version
  def pickup_libraries_array(pickup_libraries)
    pickup_libraries.map do |k|
      [Settings.libraries[k]&.label || k, k]
    end.sort
  end
end
