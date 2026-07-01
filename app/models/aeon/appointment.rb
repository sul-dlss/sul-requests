# frozen_string_literal: true

module Aeon
  # Wraps an Aeon appointment record
  class Appointment
    include ActiveModel::Model

    attr_accessor :id, :username, :reading_room_id, :start_time, :stop_time,
                  :name, :appointment_status, :reading_room, :creation_date, :available_to_proxies

    attr_reader :user

    validates :start_time, :stop_time, presence: true
    validate :stop_after_start,    if: -> { start_time && stop_time }
    validate :within_open_hours,   if: -> { reading_room && start_time && stop_time }
    validate :not_during_closure,  if: -> { reading_room && start_time && stop_time }

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

    def user=(user)
      @user = user
      @requests = nil
      @grouped_requests = nil
    end

    def requests=(requests)
      @requests = requests.reject(&:cancelled?)
      @grouped_requests = nil
    end

    def requests
      @requests ||= (user&.requests&.for_appointment(self) || []).reject(&:cancelled?)
    end

    def grouped_requests
      @grouped_requests ||= Aeon::RequestGrouping.from_requests(requests)
    end

    def date
      start_time&.to_date
    end

    def duration
      (stop_time - start_time if stop_time && start_time).to_i
    end

    def sort_key
      start_time || 100.years.from_now
    end

    def cancelled?
      appointment_status == 'Cancelled'
    end

    def edit_policy
      reading_room.appointment_min_lead_days
    end

    def editable?
      return true unless start_time

      start_time.after?(edit_policy.days.from_now)
    end

    def persisted? = id.present?

    def save # rubocop:disable Metrics/AbcSize, Naming/PredicateMethod
      return false unless valid?

      if persisted?
        Current.aeon_client.update_appointment(id, name:, start_time:, stop_time:)
      else
        saved = Current.aeon_client.create_appointment(username:, start_time:, stop_time:, name:, reading_room_id:)
        self.id = saved.id
        self.appointment_status = saved.appointment_status
        self.creation_date = saved.creation_date
        self.available_to_proxies = saved.available_to_proxies
      end
      true
    end

    private

    def stop_after_start
      errors.add(:stop_time, 'must be after start time') if stop_time <= start_time
    end

    def within_open_hours # rubocop:disable Metrics/AbcSize
      hours = reading_room.open_hours_on(start_time)

      unless hours
        return errors.add(:date, 'is outside reading room hours') if reading_room.day_only_appointments?

        return errors.add(:start_time, 'is outside reading room hours')
      end

      range = hours.range_on(start_time.to_date)
      errors.add(:start_time, 'is outside reading room hours') if start_time < range.begin || stop_time > range.end
    end

    def not_during_closure
      return unless reading_room.closures.any? { |c| c.range.overlap?(start_time..stop_time) }

      if reading_room.day_only_appointments?
        errors.add(:date, 'is during a reading room closure')
      else
        errors.add(:start_time, 'is during a reading room closure')
      end
    end
  end
end
