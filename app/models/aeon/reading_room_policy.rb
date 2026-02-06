# frozen_string_literal: true

module Aeon
  # Wraps an Aeon reading room policy record
  class ReadingRoomPolicy
    attr_reader :id, :reading_room_id, :user_status, :appointment_required,
                :appointment_min_lead_days, :appointment_max_lead_days,
                :request_min_lead_days, :request_max_lead_days,
                :auto_confirm_appointments, :appointment_reminder_days,
                :notify_appointment_received

    def self.from_dynamic(dyn) # rubocop:disable Metrics/MethodLength
      new(
        id: dyn['id'],
        reading_room_id: dyn['readingRoomID'],
        user_status: dyn['userStatus'],
        appointment_required: dyn['appointmentRequired'],
        appointment_min_lead_days: dyn['appointmentMinLeadDays'],
        appointment_max_lead_days: dyn['appointmentMaxLeadDays'],
        request_min_lead_days: dyn['requestMinLeadDays'],
        request_max_lead_days: dyn['requestMaxLeadDays'],
        auto_confirm_appointments: dyn['autoConfirmAppointments'],
        appointment_reminder_days: dyn['appointmentReminderDays'],
        notify_appointment_received: dyn['notifyAppointmentReceived']
      )
    end

    def initialize(id: nil, reading_room_id: nil, user_status: nil, appointment_required: nil, # rubocop:disable Metrics/ParameterLists
                   appointment_min_lead_days: nil, appointment_max_lead_days: nil,
                   request_min_lead_days: nil, request_max_lead_days: nil,
                   auto_confirm_appointments: nil, appointment_reminder_days: nil,
                   notify_appointment_received: nil)
      @id = id
      @reading_room_id = reading_room_id
      @user_status = user_status
      @appointment_required = appointment_required
      @appointment_min_lead_days = appointment_min_lead_days
      @appointment_max_lead_days = appointment_max_lead_days
      @request_min_lead_days = request_min_lead_days
      @request_max_lead_days = request_max_lead_days
      @auto_confirm_appointments = auto_confirm_appointments
      @appointment_reminder_days = appointment_reminder_days
      @notify_appointment_received = notify_appointment_received
    end
  end
end
