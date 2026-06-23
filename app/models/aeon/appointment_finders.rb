# frozen_string_literal: true

module Aeon
  # Wraps a group of Aeon appointments with finder methods
  class AppointmentFinders
    include Enumerable
    include ScheduledFinders

    attr_reader :appointments

    delegate :each, :-, :+, :present?, :blank?, :length, :count, :to_ary, to: :appointments

    def initialize(appointments)
      @appointments = appointments
    end

    def find(id_or_ids = nil, &)
      return super(&) if block_given?

      if id_or_ids.is_a?(Array)
        ids = id_or_ids.map(&:to_i)
        self.class.new(appointments.select { |appointment| ids.include?(appointment.id) })
      else
        id = id_or_ids.to_i
        appointments.find { |appointment| appointment.id == id }
      end
    end

    def for_reading_room(reading_room_or_id)
      id = reading_room_or_id.is_a?(Aeon::ReadingRoom) ? reading_room_or_id.id : reading_room_or_id&.to_i

      self.class.new(appointments.select { |appointment| appointment.reading_room&.id == id })
    end

    def for_site(site)
      self.class.new(appointments.select { |appointment| appointment.reading_room&.sites&.include?(site) })
    end
  end
end
