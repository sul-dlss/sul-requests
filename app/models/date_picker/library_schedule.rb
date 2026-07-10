# frozen_string_literal: true

module DatePicker
  # Schedule scoped to a Folio::Library. Provides an availability URL that the
  # date picker probes per visible month to fetch closure dates from the
  # library-hours proxy.
  class LibrarySchedule < Schedule
    include Rails.application.routes.url_helpers

    def initialize(library:, **)
      @library = library
      super(**)
    end

    def availability_url
      hours = @library&.hours_codes
      return unless hours

      closures_path(hours)
    end
  end
end
