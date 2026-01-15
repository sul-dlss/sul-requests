# frozen_string_literal: true

# LibraryHours is responsbile for determining
# if a library is open on a given day
class LibraryHours
  def initialize
    @cache = {}
  end

  def next_schedule_for(library_code, after: time)
    data = if @cache[library_code].nil?
             @cache[library_code] = fetch_schedule_for_library(library_code, after: after)
           elsif @cache[library_code].last&.last&.after?(after)
             @cache[library_code]
           else
             @cache[library_code] += fetch_schedule_for_library(library_code, after: after)
           end

    data.select { |range| range.first >= after.beginning_of_day }
  end

  def business_days_for(library_code, after: time)
    next_schedule_for(library_code, after: after).map { |range| range.first.beginning_of_day }
  end

  def open?(library_code, on:)
    business_days_for(library_code, after: on).any? { |d| d.to_date == on.to_date }
  end

  private

  def fetch_schedule_for_library(library_code, after: time, min_open_days: 7)
    library_hours(library_code, from: after.to_date, business_days: min_open_days).open_hours.filter_map do |d|
      d&.range
    end
  end

  def library_hours(library_code, **)
    location_map = Settings.libraries[library_code]&.hours

    LibraryHoursApi.get(location_map[:library_slug], location_map[:location_slug], **)
  end
end
