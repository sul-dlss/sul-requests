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
    validate :slot_available,      if: -> { reading_room && start_time && stop_time && user && errors.empty? }

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
      return [] unless persisted?

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
      appointment_status == 'Cancelled' || (requests.none? && !editable?)
    end

    def edit_policy
      reading_room.appointment_min_lead_days
    end

    def editable?
      return true unless start_time

      start_time.after?(edit_policy.days.from_now)
    end

    def persisted? = id.present?

    def save # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
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
    rescue AeonClient::ApiError => e
      Honeybadger.notify(e)
      action = persisted? ? 'updated' : 'created'
      errors.add(:base, "This appointment could not be #{action}. Please refresh and try again.")
      false
    end

    def range
      start_time..stop_time if start_time && stop_time
    end

    private

    def stop_after_start
      errors.add(:stop_time, 'must be after start time') if stop_time <= start_time
    end

    def within_open_hours
      hours = reading_room.open_hours_on(start_time)
      return errors.add(time_error_field, 'is outside reading room hours') unless hours

      range = hours.range_on(start_time.to_date)
      errors.add(time_error_field, 'is outside reading room hours') if start_time < range.begin || stop_time > range.end
    end

    def not_during_closure
      return unless reading_room.closures.any? { |c| c.range.overlap?(range) }

      errors.add(time_error_field, 'is during a reading room closure')
    end

    def slot_available
      return if AppointmentSlotAvailability.new(reading_room:, user:).available_at?(range:, excluding_id: id)

      errors.add(time_error_field, 'is not available')
    end

    def time_error_field
      reading_room.day_only_appointments? ? :date : :start_time
    end
  end
end
