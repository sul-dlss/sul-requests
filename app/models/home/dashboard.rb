# frozen_string_literal: true

module Home
  # Home page presenter wrapping user data for both view variants.
  class Dashboard
    DigitizationStatus = Data.define(:count, :label)

    attr_reader :aeon, :patron

    def initialize(aeon:, patron:)
      @aeon = aeon
      @patron = patron
    end

    def folio? = patron.present?
    def aeon? = aeon.present?

    def checkouts
      @checkouts ||= patron.checkouts.sort_by { |c| c.sort_key(:due_date) }
    end

    def actionable_borrowed_items
      @actionable_borrowed_items ||= checkouts.select { |c| c.due_date && c.due_date <= 3.days.from_now }
    end

    def fines
      @fines ||= patron.fines
    end

    def balance
      @balance ||= fines.sum { |f| f.owed || 0 }
    end

    def pickup_requests
      @pickup_requests ||= patron.requests
    end

    def ready_for_pickup
      @ready_for_pickup ||= pickup_requests.select(&:ready_for_pickup?)
    end

    def digital_requests
      @digital_requests ||= aeon.requests.digitization.submitted.newest_first
    end

    def recently_delivered_digital_requests
      @recently_delivered_digital_requests ||= aeon.requests.digitization.recently_delivered.newest_first(&:delivered_date)
    end

    def appointments
      @appointments ||= aeon.appointments
    end

    def appointment_requests_count
      @appointment_requests_count ||= appointments.sum { |a| a.requests.count }
    end

    def next_appointment_date
      @next_appointment_date ||= upcoming_appointments.first&.start_time&.to_date
    end

    def upcoming_appointments
      @upcoming_appointments ||= appointments.upcoming(within: 7.days, fallback: 3)
    end

    def saved_for_later
      @saved_for_later ||= aeon.requests.saved_for_later.newest_first
    end

    def next_activity_date
      first_activity = upcoming_activities&.first
      @next_activity_date ||= first_activity&.start_time&.to_date
    end

    def upcoming_activities
      @upcoming_activities ||= aeon.activities&.active&.upcoming(within: 7.days, fallback: 3)
    end
  end
end
