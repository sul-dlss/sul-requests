# frozen_string_literal: true

module Aeon
  # Handle logic for updating  display after one or more requests are updated.
  class UpdateResponseService
    attr_reader :original_requests, :updated_requests

    def initialize(original_requests, updated_requests)
      @original_requests = Aeon::RequestFinders.new(original_requests)
      @updated_requests = Aeon::RequestFinders.new(updated_requests)
    end

    def next_requests
      @next_requests ||= begin
        updated_ids = updated_requests.map(&:id)
        arr = (original_requests.reject { |r| updated_ids.include? r.id } + updated_requests).sort_by do |x|
          [x.title, x.sort_key, -1 * x.creation_date.to_i]
        end

        Aeon::RequestFinders.new(arr)
      end
    end

    def requests_to_update
      return to_enum(:requests_to_update) unless block_given?

      updated_requests.each do |request|
        yield request, original_requests.find { |r| r.id == request.id }
      end
    end

    def previous_aeon_request_groups
      @previous_aeon_request_groups ||= Aeon::RequestGrouping.from_requests(original_requests)
    end

    def next_aeon_request_groups
      @next_aeon_request_groups ||= Aeon::RequestGrouping.from_requests(next_requests)
    end

    def saved_for_later_sidebar_needs_update?
      next_requests.saved_for_later.reading_room.map(&:id) != original_requests.saved_for_later.reading_room.map(&:id)
    end

    # figuring out how to properly sort saved for later requests is a little annoying, so we just update the entire sidebar when we need to
    def saved_for_later_request_groups
      @saved_for_later_request_groups ||= Aeon::RequestGrouping.from_requests(next_requests.saved_for_later.reading_room)
    end

    def appointments_to_update # rubocop:disable Metrics/AbcSize
      requests_to_update.reject { |r1, r2| r1.appointment_id == r2.appointment_id }
                        .flat_map { |r1, r2| [r1.appointment, r2.appointment] }
                        .flatten
                        .compact.uniq(&:id).map do |appointment|
                          appointment.tap do |appt|
                            appt.requests = next_requests.for_appointment(appt)
                          end
                        end
    end

    def activities_to_update
      requests_to_update.select { |r1, r2| activity_display_affected?(r1, r2) }
                        .flat_map { |r1, r2| [r1.activity, r2.activity] }
                        .flatten
                        .compact.uniq(&:id).map do |activity|
                          activity.tap do |appt|
                            appt.requests = next_requests.for_activity(activity)
                          end
                        end
    end

    private

    def activity_display_affected?(updated, original)
      updated.activity_id != original.activity_id ||
        (updated.activity? && updated.status != original.status)
    end
  end
end
