# frozen_string_literal: true

module Aeon
  # Wraps an Aeon appointment record
  class Appointment
    include ActiveModel::Model

    attr_accessor :id, :username, :reading_room_id, :start_time, :stop_time,
                  :name, :appointment_status, :reading_room, :creation_date, :available_to_proxies

    attr_writer :requests

    def self.from_dynamic(dyn) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      new(
        id: dyn['id'],
        username: dyn['username'],
        start_time: dyn['startTime'] && Time.zone.parse(dyn['startTime']),
        stop_time: dyn['stopTime'] && Time.zone.parse(dyn['stopTime']),
        name: dyn['name'],
        available_to_proxies: dyn['availableToProxies'],
        appointment_status: dyn['appointmentStatus'],
        reading_room: dyn['readingRoom'] ? ReadingRoom.from_dynamic(dyn['readingRoom']) : nil,
        reading_room_id: dyn['readingRoomID'],
        creation_date: Time.zone.parse(dyn.fetch('creationDate'))
      )
    end

    def available_to_proxies?
      @available_to_proxies
    end

    def reading_room?
      reading_room_id.present?
    end

    def requests
      @requests ||= []
    end

    def date
      start_time&.to_date
    end

    def sort_key
      start_time || 100.years.from_now
    end

    def cancelled?
      appointment_status == 'Cancelled'
    end

    def edit_policy
      reading_room.policies.first.appointment_min_lead_days
    end

    def editable?
      start_time.after?(edit_policy.days.from_now)
    end

    def persisted? = id.present?
  end
end
