# frozen_string_literal: true

# Renders the custom Stimulus date picker. A DatePicker::Schedule supplies the
# domain-specific window, open days, closures, and (optionally) an availability
# URL the picker probes per visible month.
#
# Usage:
#   <%= render DatePickerComponent.new(:date, form: f) %>
#   <%= render DatePickerComponent.new(:date, form: f,
#             schedule: DatePicker::LibrarySchedule.new(library: pickup.library)) %>
class DatePickerComponent < ViewComponent::Base
  attr_reader :key, :form, :data, :schedule

  def initialize(key, form: nil, data: {}, schedule: DatePicker::Schedule.new)
    @key = key
    @form = form
    @data = data
    @schedule = schedule
  end

  def lead_time
    return unless schedule.max

    days = (schedule.max.to_date - Time.zone.today).to_i
    if days < 365
      pluralize(days, 'day')
    else
      pluralize(days / 365, 'year')
    end
  end

  def controller_data # rubocop:disable Metrics/AbcSize
    data.merge(controller: "date-picker #{data[:controller]}".strip).reverse_merge(
      'date-picker-today-value': Time.zone.today.iso8601,
      'date-picker-min-value': schedule.min,
      'date-picker-max-value': schedule.max,
      'date-picker-open-days-value': schedule.open_days,
      'date-picker-availability-url-value': schedule.availability_url,
      'date-picker-disabled-value': schedule.disabled_dates.presence
    ).compact
  end
end
