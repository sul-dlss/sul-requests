# frozen_string_literal: true

module Aeon
  # Wraps a group of Aeon requests with finder methods
  class RequestFinders
    include Enumerable

    attr_reader :requests

    delegate :each, :-, :+, :present?, :blank?, :length, :count, :to_ary, to: :requests

    def initialize(requests)
      @requests = requests
    end

    def find(id_or_ids = nil, &)
      return super(&) if block_given?

      if id_or_ids.is_a?(Array)
        ids = id_or_ids.map(&:to_i)
        self.class.new(requests.select { |request| ids.include?(request.id) })
      else
        id = id_or_ids.to_i
        requests.find { |request| request.id == id }
      end
    end

    def for_activities
      self.class.new(requests.select(&:activity?))
    end

    def for_activity(activity_or_id)
      id = activity_or_id.is_a?(Aeon::Activity) ? activity_or_id.id : activity_or_id&.to_i

      self.class.new(requests.select { |request| request.activity_id == id })
    end

    def for_appointment(appointment_or_id)
      id = appointment_or_id.is_a?(Aeon::Appointment) ? appointment_or_id.id : appointment_or_id&.to_i

      self.class.new(requests.select { |request| request.appointment_id == id })
    end

    def for_reading_room(reading_room_or_id)
      id = reading_room_or_id.is_a?(Aeon::ReadingRoom) ? reading_room_or_id.id : reading_room_or_id&.to_i

      self.class.new(requests.select { |request| !request.digital? && request.reading_room&.id == id })
    end

    def select(&)
      self.class.new(requests.select(&))
    end

    def reject(&)
      self.class.new(requests.reject(&))
    end

    def sort_by(&)
      self.class.new(requests.sort_by(&))
    end

    # Sorts requests newest-first by `creation_date`, rounded to the minute,
    # with title and sort_key as tiebreakers. Pass a block to sort by a
    # different timestamp accessor (e.g. `&:transaction_date`).
    def newest_first(&date_block)
      date_block ||= :creation_date.to_proc
      self.class.new(requests.sort_by { |r| [-date_block.call(r).change(sec: 0).to_i, r.title.to_s, r.default_sort_key] })
    end

    def saved_for_later
      self.class.new requests.select(&:saved_for_later?)
    end

    def submitted
      self.class.new requests.select(&:submitted?)
    end

    def cancelled
      self.class.new requests.select(&:cancelled?)
    end

    def completed
      self.class.new requests.select(&:completed?)
    end

    def digitization
      self.class.new requests.select(&:digital?)
    end

    def recently_delivered(within: 3.days)
      self.class.new(requests.select { |r| r.delivered_recently?(within: within) })
    end

    def reading_room
      self.class.new requests.reject(&:digital?)
    end
  end
end
