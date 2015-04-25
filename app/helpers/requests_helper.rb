###
#  Helper module for requests related markup
###
module RequestsHelper
  def select_for_pickup_libraries(form)
    pickup_libraries = form.object.library_location.pickup_libraries
    return unless pickup_libraries.present?
    select_for_multiple_libraries(form, pickup_libraries) || single_library_markup(form, pickup_libraries.first)
  end

  def label_for_pickup_libraries_dropdown(pickup_libraries)
    if pickup_libraries.many?
      'Deliver to'
    else
      'Must be used in'
    end
  end

  private

  def select_for_multiple_libraries(form, pickup_libraries)
    return unless pickup_libraries.keys.length > 1
    form.select :destination,
                pickup_libraries_array(pickup_libraries),
                label: label_for_pickup_libraries_dropdown(pickup_libraries)
  end

  def single_library_markup(form, library)
    <<-HTML
      <div class='form-group'>
        <div class='#{label_column_class} control-label'>#{label_for_pickup_libraries_dropdown([])}</div>
        <div class='#{content_column_class} input-like-text'>#{library.last}</div>
        #{form.hidden_field :destination, value: library.first}
      </div>
    HTML
  end

  def pickup_libraries_array(pickup_libraries)
    pickup_libraries.map do |k, v|
      [v, k]
    end
  end
end
