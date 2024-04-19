# frozen_string_literal: true

###
#  PagingSchedule takes a requested item and can
#  read the paging schedule configuration and estimate a date of arrival.
###
module PagingSchedule
  class << self
    def schedule
      @schedule ||= Settings.paging_schedule.map do |sched|
        PagingSchedule::Scheduler.new(**sched)
      end
    end

    def for(request, scan: false)
      return schedule_for_request_scan(request) if scan

      schedule_or_default = schedule_for_request(request) || default_schedule(request)
      raise ScheduleNotFound unless schedule_or_default.present?

      schedule_or_default
    end

    def worst_case_delivery_day
      (Time.zone.today + worst_case_days_later.days)
    end

    private

    def schedule_for_request(request)
      schedule.detect do |sched|
        sched.from == request.origin_library_code &&
          sched.to == request.destination_library_code &&
          sched.by_time?(request.created_at)
      end
    end

    def schedule_for_request_scan(request)
      schedule.detect do |sched|
        sched.from == request.origin_library_code &&
          sched.to == request.scan_code &&
          sched.by_time?(request.created_at)
      end
    end

    def default_schedule(request)
      s = schedule.detect do |sched|
        sched.from == request.origin_library_code &&
          sched.to == :anywhere &&
          sched.by_time?(request.created_at)
      end
      s&.for(request.destination_library_code)
    end

    def worst_case_days_later
      schedule.filter_map(&:business_days_later).max + Settings.worst_case_paging_padding
    end
  end

  ###
  #  Scheduler class handles the logic behind defining how many days a given
  #  request will take based on the PagingSchedule configuration.
  ###
  class Scheduler
    attr_reader :to, :from, :before, :after, :business_days_later, :will_arrive_after

    # rubocop:disable Metrics/ParameterLists
    def initialize(to:, from:, before: nil, after: nil, business_days_later: nil, will_arrive_after: nil)
      @to = to
      @from = from
      @before = before
      @after = after
      @business_days_later = business_days_later.to_i
      @will_arrive_after = will_arrive_after
    end
    # rubocop:enable Metrics/ParameterLists

    def for(dest)
      Scheduler.new(to: dest,
                    from:,
                    before:,
                    after:,
                    business_days_later:,
                    will_arrive_after:)
    end

    def earliest_delivery_estimate(time = Time.zone.now)
      Estimate.new(self, time)
    end

    def will_arrive_text
      @will_arrive_text ||= "after #{will_arrive_after}"
    end

    def by_time?(created_at = nil)
      created_at ||= Time.zone.now
      case
      when before
        created_at < Time.zone.parse(before)
      when after
        created_at >= Time.zone.parse(after)
      end
    end

    def valid?(date)
      date >= earliest_delivery_estimate.estimated_delivery_day_to_destination && destination_open?(date)
    end

    def destination_open?(date)
      LibraryHours.new(to).open?(date)
    end

    # Simple class to return estimates
    class Estimate
      attr_accessor :to
      attr_reader :from, :business_days_later, :time, :as_of

      def initialize(scheduler, as_of = Time.zone.now)
        @to = scheduler.to
        @from = scheduler.from
        @business_days_later = scheduler.business_days_later
        @time = scheduler.will_arrive_text
        @as_of = as_of
      end

      def as_json(*)
        {
          date: estimated_delivery_day_to_destination,
          time:,
          text: to_s
        }
      end

      def to_s
        "#{I18n.l(estimated_delivery_day_to_destination, format: :long)} #{time}"
      end

      def estimated_delivery_day_to_destination
        @estimated_delivery_day_to_destination ||= destination_library_hours_next_business_day_after_delivery
        @estimated_delivery_day_to_destination ||= PagingSchedule.worst_case_delivery_day
      end

      private

      def origin_library_next_business_day
        LibraryHours.new(from).next_business_day(as_of, business_days_later)
      end

      def destination_library_hours_next_business_day_after_delivery
        LibraryHours.new(to).next_business_day(origin_library_next_business_day)
      end
    end
  end

  class ScheduleNotFound < StandardError
  end
end
