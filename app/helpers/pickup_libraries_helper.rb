# frozen_string_literal: true

##
# Helpers for formatting and displaying pickup libraries
module PickupLibrariesHelper
  # Pickup libraries for Symphony
  def select_for_pickup_libraries(form)
    pickup_libraries = form.object.pickup_libraries
    return unless pickup_libraries.present?
    select_for_multiple_libraries(form, pickup_libraries) || single_library_markup(form, pickup_libraries.first)
  end

  def label_for_pickup_libraries_dropdown(pickup_libraries)
    if pickup_libraries.many?
      'Deliver to'
    else
      'Will be delivered to'
    end
  end

  # Service points for FOLIO
  def select_for_pickup_service_points(form)
    pickup_service_points = form.object.pickup_service_points
    return unless pickup_service_points.present?

    select_for_multiple_service_points(form, pickup_service_points) || single_service_point_markup(form, pickup_service_points.first)
  end

  private

  # Symphony
  def select_for_multiple_libraries(form, pickup_libraries)
    return unless pickup_libraries.length > 1
    form.select(
      :destination,
      pickup_libraries_array(pickup_libraries),
      {
        label: label_for_pickup_libraries_dropdown(pickup_libraries),
        selected: form.object.destination || form.object.default_pickup_library
      },
      aria: { controls: 'scheduler-text' },
      data: { 'paging-schedule-updater' => 'true', 'text-selector' => "[data-text-object='#{form.object.object_id}']" }
    )
  end

  def single_library_markup(form, library)
    <<-HTML
      <div class='form-group'>
        <div class='#{label_column_class} control-label'>
          #{label_for_pickup_libraries_dropdown([])}
        </div>
        <div class='#{content_column_class} input-like-text'>
          #{Settings.libraries[library]&.label || library}
        </div>
        #{form.hidden_field :destination, value: library}
      </div>
    HTML
  end

  def pickup_libraries_array(pickup_libraries)
    pickup_libraries.map do |k|
      [Settings.libraries[k]&.label || k, k]
    end.sort
  end

  # Using service points for FOLIO
  def select_for_multiple_service_points(form, pickup_service_points)
    return unless pickup_service_points.length > 1

    form.select(
      :destination,
      pickup_service_points_array(pickup_service_points),
      {
        label: label_for_pickup_libraries_dropdown(pickup_service_points),
        selected: form.object.destination || form.object.default_pickup_service_point
      },
      aria: { controls: 'scheduler-text' },
      data: { 'paging-schedule-updater' => 'true', 'text-selector' => "[data-text-object='#{form.object.object_id}']" }
    )
  end

  def single_service_point_markup(form, service_point)
    <<-HTML
      <div class='form-group'>
        <div class='#{label_column_class} control-label'>
          #{label_for_pickup_libraries_dropdown([])}
        </div>
        <div class='#{content_column_class} input-like-text'>
          #{get_service_point_name(service_point) || service_point}
        </div>
        #{form.hidden_field :destination, value: service_point}
      </div>
    HTML
  end

  # Given an array of service point codes
  def pickup_service_points_array(pickup_service_points)
    # We want an array of arrays, with first element being label, second being code
    # First create hash by service point code to enable easier lookup
    service_points_hash = {}
    Folio::Types.instance.service_points.values.each do |service_point|
      service_points_hash[service_point.code] = service_point
    end 
    pickup_service_points.map do |code|
      sp = service_points_hash[code]
      [sp.name, code]
    end
  end

  # Get the name for the service point given the code
  def get_service_point_name(code)
    # Find the service point with the same code, and return the name
    Folio::Types.instance.service_points.values.find { |v| v.code == code }&.name
  end
end
