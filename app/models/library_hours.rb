# frozen_string_literal: true

# LibraryHours is responsbile for determining
# if a library is open on a given day
class LibraryHours
  def initialize(library_code)
    @library = library_code
  end

  def open?(date)
    library_hours(from: date).open?
  end

  def business_days(from, min_open_days: 1)
    library_hours(from:, business_days: min_open_days).open_hours
  end

  def next_business_day(from, n = 0)
    library_hours(from:, business_days: n + 1).open_hours.last.try(:day)
  end

  private

  def library_hours(range = {})
    LibraryHoursApi.get(library_slug, location_slug, range)
  end

  def library
    config.scanning_library_proxy[@library] || @library
  end

  def library_slug
    location_map[:library_slug]
  end

  def location_slug
    location_map[:location_slug]
  end

  def location_map
    Settings.libraries[library]&.hours
  end

  def config
    SULRequests::Application.config
  end
end
