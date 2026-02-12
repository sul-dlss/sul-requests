# frozen_string_literal: true

module Aeon
  # Wraps an Aeon appointment record
  class AppointmentGrouping
    def self.from_appointments(appointments)
      appointments.group_by { |appt| [appt.reading_room&.id, appt.start_time.to_date] }.each_value.map do |group|
        new(group.sort_by(&:sort_key))
      end
    end

    delegate :reading_room, to: :first
    delegate :first, to: :appointments

    attr_reader :appointments

    def initialize(appointments)
      @appointments = appointments
    end

    def date
      first.start_time.to_date
    end

    def requests
      appointments.flat_map(&:requests)
    end
  end
end
