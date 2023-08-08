# frozen_string_literal: true

###
#  PagingScheduleEstimate is a module that takes a requested item and can
#  read the paging schedule configuration and estimate a date of arrival.
###
class PagingSchedule
  class_attribute :schedule, default: []

  SAL3_COORDINATES = %w[
    HILA-SAL3-STACKS
    LANE-SAL3
    LANE-SAL3X
    BUS-SAL3-STACKS
    BUS-SAL3-PAGE-BU
    SPEC-SAL3-MSS
  ].freeze

  class << self
    def configure(&)
      instance_eval(&)
    end

    def for(request)
      new(request).schedule_or_default
    end

    def when_paging(to:, from:, before: nil, after: nil, &block)
      schedule << Scheduler.new(to:, from:, before:, after:, &block)
    end

    def worst_case_delivery_day
      (Time.zone.today + worst_case_days_later.days)
    end

    private

    def worst_case_days_later
      schedule.filter_map(&:days_later).max + Settings.worst_case_paging_padding
    end
  end

  def initialize(request)
    @request = request
  end

  def schedule_or_default
    schedule_for_destination || default_schedule || raise(ScheduleNotFound)
  end

  private

  attr_reader :request

  delegate :destination, :created_at, to: :request, prefix: 'target'

  def target_origin
    @target_origin ||= SAL3_COORDINATES.include?(request.origin) ? 'SAL3' : request.origin
  end

  def schedule_for_destination
    schedule.detect do |sched|
      sched.from == target_origin &&
        sched.to == target_destination &&
        sched.by_time?(target_created_at)
    end
  end

  def default_schedule
    scheduler = schedule.detect do |sched|
      sched.from == target_origin &&
        sched.to == :anywhere &&
        sched.by_time?(target_created_at)
    end
    scheduler&.for(target_destination)
  end

  ###
  #  Scheduler class handles the logic behind defining how many days a given
  #  request will take based on the PagingSchedule configuration.
  ###
  class Scheduler
    attr_reader :to, :from, :before, :after, :days_later, :will_arrive_text

    # rubocop:disable Metrics/ParameterLists
    def initialize(to:, from:, before: nil, after: nil, days_later: nil, will_arrive_text: nil, &block)
      @to = to
      @from = from
      @before = before
      @after = after
      @days_later = days_later
      @will_arrive_text = will_arrive_text
      @schedule = instance_eval(&block) if block
    end
    # rubocop:enable Metrics/ParameterLists

    def for(dest)
      Scheduler.new(to: dest,
                    from:,
                    before:,
                    after:,
                    days_later:,
                    will_arrive_text:)
    end

    def earliest_delivery_estimate(time = Time.zone.now)
      Estimate.new(self, time)
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

    def valid?(date)
      date >= earliest_delivery_estimate.estimated_delivery_day_to_destination && destination_open?(date)
    end

    def destination_open?(date)
      LibraryHours.new(to).open?(date)
    end

    # Simple class to return estimates
    class Estimate
      attr_accessor :to
      attr_reader :from, :days_later, :time, :as_of

      def initialize(scheduler, as_of = Time.zone.now)
        @to = scheduler.to
        @from = scheduler.from
        @days_later = scheduler.days_later
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
        LibraryHours.new(from).next_business_day(as_of, days_later)
      end

      def destination_library_hours_next_business_day_after_delivery
        LibraryHours.new(to).next_business_day(origin_library_next_business_day)
      end
    end
  end

  class ScheduleNotFound < StandardError
  end
end
