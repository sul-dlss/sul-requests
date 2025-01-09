# frozen_string_literal: true

###
#  PagingSchedule takes a requested item and can
#  read the paging schedule configuration and estimate a date of arrival.
###
class PagingSchedule
  class << self
    def schedule
      @schedule ||= Settings.paging_schedule.map do |sched|
        PagingSchedule::Scheduler.new(**sched)
      end
    end

    def for(from:, to:, scan: false, library_code: nil)
      instance = new(from:, to:, library_code:)

      if scan
        instance.schedule_for_request_scan
      else
        instance.schedule_for_request
      end
    end

    def worst_case_delivery_day
      (Time.zone.today + worst_case_days_later.days)
    end

    def worst_case_days_later
      schedule.filter_map(&:business_days_later).max + Settings.worst_case_paging_padding
    end
  end

  attr_reader :from, :to, :library_code, :time

  def initialize(from:, to:, time: nil, library_code: nil)
    @from = from
    @to = to
    @library_code = library_code
    @time = time || Time.zone.now
  end

  def schedule
    self.class.schedule
  end

  def schedule_for_request
    schedule_or_default = schedule_for_destination || default_schedule

    raise ScheduleNotFound unless schedule_or_default.present?
    raise ScheduleNotFound if from&.pages_prefer_to_send_via_illiad?

    schedule_or_default
  end

  def schedule_for_request_scan
    schedule.detect do |sched|
      sched.from == origin_library_code &&
        sched.to == destination_library_code &&
        sched.by_time?(time)
    end
  end

  def schedule_for_destination
    schedule.detect do |sched|
      sched.from == origin_library_code &&
        sched.to == destination_library_code &&
        sched.by_time?(time)
    end
  end

  def default_schedule
    s = schedule.detect do |sched|
      sched.from == origin_library_code &&
        sched.to == :anywhere &&
        sched.by_time?(time)
    end
    s&.for(to)
  end

  def origin_library_code
    from&.paging_schedule_origin_library_code || @library_code
  end

  def destination_library_code
    @destination_library_code ||= Settings.ils.pickup_destination_class.constantize.new(to).library_code || to
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
      @will_arrive_text ||= will_arrive_after
    end

    def by_time?(created_at)
      case
      when before
        created_at < Time.zone.parse(before)
      when after
        created_at >= Time.zone.parse(after)
      else # the schedule doesn't specify before/after
        true
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
        "#{I18n.l(estimated_delivery_day_to_destination, format: :long)}, #{time}"
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
        to_code = Settings.libraries[to] ? to : Folio::Types.service_points.find_by(code: to)&.library&.code
        LibraryHours.new(to_code).next_business_day(origin_library_next_business_day)
      end
    end
  end

  class ScheduleNotFound < StandardError
  end
end
