###
#  PagingScheduleEstimate is a module that takes a requested item and can
#  read the paging schedule configuration and estimate a date of arrival.
###
module PagingSchedule
  mattr_accessor :schedule do
    []
  end

  class << self
    def configure(&block)
      instance_eval(&block)
    end

    def when_paging(to:, from:, before: nil, after: nil, &block)
      schedule << Scheduler.new(to: to, from: from, before: before, after: after, &block)
    end

    def for(request)
      schedule_or_default = schedule_for_request(request) || default_schedule(request)
      fail ScheduleNotFound unless schedule_or_default.present?
      schedule_or_default
    end

    private

    def schedule_for_request(request)
      schedule.detect do |sched|
        sched.from == request.origin &&
          sched.to == request.destination &&
          sched.by_time?(request.created_at)
      end
    end

    def default_schedule(request)
      s = schedule.detect do |sched|
        sched.from == request.origin &&
        sched.to == :anywhere &&
        sched.by_time?(request.created_at)
      end
      s.estimate.to = request.destination if s
      s
    end
  end

  ###
  #  Scheduler class handles the logic behind defining how many days a given
  #  request will take based on the PagingSchedule configuration.
  ###
  class Scheduler
    attr_reader :to, :from, :before, :after, :days_later, :will_arrive_text
    def initialize(to:, from:, before: nil, after: nil, &block)
      @to = to
      @from = from
      @before = before
      @after = after
      @schedule = instance_eval(&block)
    end

    def estimate
      @estimate ||= Estimate.new(self)
    end

    def business_days_later(days)
      @days_later = days.to_i
    end

    def will_arrive(options)
      @will_arrive_text = case
                          when options[:before]
                            "before #{options[:before]}"
                          when options[:after]
                            "after #{options[:after]}"
                          end
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

    # Simple class to return estimates
    class Estimate
      attr_accessor :to
      attr_reader :from, :days_later, :time
      def initialize(scheduler)
        @to = scheduler.to
        @from = scheduler.from
        @days_later = scheduler.days_later
        @time = scheduler.will_arrive_text
      end

      def date
        estimated_delivery_day_to_destination
      end

      def as_json(*)
        {
          date: date,
          time: time,
          text: to_s,
          destination_business_days: destination_library_hours[to].business_days
        }
      end

      def to_s
        "#{I18n.l(date, format: :long)}, #{time}"
      end

      private

      def origins_library_hours
        @origins_library_hours ||= LibraryHours.new(from)
      end

      # Create a cache of all destinations requested for this
      # origin's estimate so we don't request multiple times
      def destination_library_hours
        @destination_library_hours ||= {}
        @destination_library_hours[to] ||= LibraryHours.new(to)
        @destination_library_hours
      end

      def origins_next_business_day
        # Time.zone.today is a fall back. We have request libraries that don't exist in the API
        @origins_next_business_day ||= origins_library_hours.next_business_day || Time.zone.today
      end

      def origins_business_day_index
        origins_library_hours.business_days.index(origins_next_business_day)
      end

      def business_days_later_after_origin_is_open
        return Time.zone.today + days_later.days unless origins_business_day_index.present?
        origins_library_hours.business_days[origins_business_day_index + days_later]
      end

      def estimated_delivery_day_to_destination
        # Time.zone.today is a fall back. We have request libraries that don't exist in the API
        destination_library_hours[to].next_business_day(business_days_later_after_origin_is_open) || Time.zone.today
      end
    end
  end

  class ScheduleNotFound < StandardError
  end
end
