# frozen_string_literal: true

# Renders the custom Stimulus date-picker for the appointment date field.
#
# Usage:
#   <%= render DatePickerComponent.new(:date, form: f) %>
#   <%= render DatePickerComponent.new(:date, form: f,
#             data: { 'date-picker-disabled-value': ['2026-05-01'], 'date-picker-marked-value': ['2026-05-10'] }) %>
class DatePickerComponent < ViewComponent::Base
  attr_reader :key, :form, :data

  def initialize(key, form: nil, data: {})
    @key = key
    @form = form
    @data = data
  end

  def open_days
    Date::DAYNAMES
  end

  def min
    Time.zone.today.iso8601
  end

  # TODO: See if this is right or if we want fewer years
  def max
    (Time.zone.today + 3.years).iso8601
  end

  def lead_time
    return unless max

    days = (max.to_date - Time.zone.today).to_i
    if days < 365
      pluralize(days, 'day')
    else
      pluralize(days / 365, 'year')
    end
  end

  def controller_data
    data.merge(controller: "date-picker #{data[:controller]}").reverse_merge(
      'date-picker-min-value': min,
      'date-picker-max-value': max,
      'date-picker-open-days-value': open_days,
      'date-picker-today-value': Time.zone.today.iso8601
    )
  end
end
