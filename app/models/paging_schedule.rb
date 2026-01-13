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

    def for(**)
      instance = new(**)
      instance.schedule_for_request
    end

    def worst_case_delivery_day
      (Time.zone.today + worst_case_days_later.days)
    end

    def worst_case_days_later
      schedule.filter_map(&:business_days_later).max + Settings.worst_case_paging_padding
    end
  end

  attr_reader :from, :to, :time

  def initialize(from:, to:, time: nil, library_code: nil)
    @from = from
    @to = to
    @origin_library_code = library_code
    @time = time || Time.zone.now
  end

  delegate :schedule, to: :class

  def earliest_delivery_estimate
    Estimate.new(self, as_of: time)
  end

  # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
  def schedule_for_request(details: false)
    raise ScheduleNotFound if from&.pages_prefer_to_send_via_illiad?
    return schedule_for_request_scan(details:) if to == 'SCAN'

    steps = { meta: { from: origin_library_code, to: to }, request: time }

    # paging schedule:
    # when the request comes in

    # figure out when the next shelf pull happens
    pull_schedule = Array(Settings.library_pull_schedule[origin_library_code])
    origin_open_days = origin_library_hours.business_days(time, min_open_days: 2).filter_map { |d| d&.day&.to_time }
    steps[:shelf_pull] = next_action_time(origin_open_days, pull_schedule, after: time)

    if origin_library_code == destination_library_code || (origin_library_code == 'MEDIA-CENTER' && destination_library_code == 'GREEN')
      # direct delivery without mailroom processing
      steps[:mailroom_delivery] = steps[:shelf_pull]
    else
      # add a little time for staff packing?
      steps[:ready_to_ship] = steps[:shelf_pull].advance(minutes: 5)

      if origin_library_code == 'MARINE-BIO'
        steps[:courier_delivery_to_green] = [steps[:ready_to_ship].next_occurring(:tuesday),
                                             steps[:ready_to_ship].next_occurring(:thursday)].min.change(hour: 12, min: 0, sec: 0)
      end

      shipped = steps[:courier_delivery_to_green] || steps[:ready_to_ship]

      # get the next 3 business days after the ready-to-ship time for the mailroom
      mailroom_open_days = LibraryHours.new('GREEN').business_days(shipped, min_open_days: 7).filter_map do |d|
        d&.day&.to_time
      end.reject(&:on_weekend?)

      steps[:mailroom_pickup] = next_action_time(mailroom_open_days, Settings.mailroom[origin_library_code], after: shipped)

      steps[:mailroom_sort] = next_action_time(mailroom_open_days, Settings.mailroom.sorted_by, after: steps[:mailroom_pickup])

      if destination_library_code == 'MARINE-BIO'
        steps[:courier_delivery_to_mar] = [steps[:mailroom_sort].next_occurring(:monday),
                                           steps[:mailroom_sort].next_occurring(:wednesday),
                                           steps[:mailroom_sort].next_occurring(:friday)].min.change(hour: 17, min: 0, sec: 0)

        destination_delivery_open_days = destination_library_hours.business_days(steps[:courier_delivery_to_mar],
                                                                                 min_open_days: 2).filter_map do |d|
          d&.day&.to_time
        end
        steps[:mailroom_delivery] = next_action_time(destination_delivery_open_days,
                                                     Settings.mailroom[destination_library_code], after: steps[:courier_delivery_to_mar])
      else
        destination_delivery_open_days = destination_library_hours.business_days(steps[:mailroom_sort],
                                                                                 min_open_days: 2).filter_map do |d|
          d&.day&.to_time
        end
        steps[:mailroom_delivery] = next_action_time(mailroom_open_days & destination_delivery_open_days,
                                                     Settings.mailroom[destination_library_code], after: steps[:mailroom_sort])
      end

    end

    # add constant unpacking/staff checkin delay / schedule
    checkin_processing_hours = Settings.hold_shelf_staff_checkin_delay_hours[destination_library_code] || Settings.hold_shelf_staff_checkin_delay_hours.default
    steps[:staff_processed] = steps[:mailroom_delivery].advance(hours: checkin_processing_hours)
    # account for minimum transit days / staff processing time

    if Settings.minimum_library_processing_days[origin_library_code] && (steps[:staff_processed] - steps[:shelf_pull] < Settings.minimum_library_processing_days[origin_library_code].days)
      steps[:ready] = steps[:shelf_pull] + Settings.minimum_library_processing_days[origin_library_code].days
    elsif Settings.library_staff_checkin_schedule[destination_library_code]
      destination_open_days = destination_library_hours.business_days(steps[:staff_processed],
                                                                      min_open_days: 3).filter_map do |d|
        d&.day&.to_time
      end

      steps[:ready] = next_action_time(destination_open_days,
                                       Settings.library_staff_checkin_schedule[destination_library_code],
                                       after: steps[:staff_processed])
    else
      steps[:ready] = steps[:staff_processed]
    end

    # check destination opening hours, or punt to the next business day
    steps[:available_to_patron] = next_open_time_after(destination_library_hours, steps[:ready])

    if details
      steps
    else
      steps[:available_to_patron]
    end
  end

  def next_open_time_after(library_hours, after_time)
    destination_library_hours = library_hours.business_days(after_time, min_open_days: 2)

    if destination_library_hours.first.range.cover?(after_time + 5.minutes)
      after_time
    elsif destination_library_hours.first.range.begin.after?(after_time)
      destination_library_hours.first.range.begin
    else
      destination_library_hours.second.range.begin
    end
  end

  def schedule_for_request_scan(details: false)
    # scan schedule:
    scan_destination_library_code = from.details['scanServicePointCode'] || 'GREEN'
    steps = PagingSchedule.new(from: from, to: scan_destination_library_code, time: time).schedule_for_request(details: true)
    steps[:meta][:for] = 'SCAN'

    steps[:scan_processed] =
      steps[:available_to_patron] + (Settings.scan[scan_destination_library_code]&.scan_processing_days || Settings.scan.default.scan_processing_days).days
    scan_destination_library_hours = LibraryHours.new(scan_destination_library_code).business_days(steps[:scan_processed],
                                                                                                   min_open_days: 3).filter_map do |d|
      d&.day&.to_time
    end

    steps[:scan_delivered] = next_action_time(scan_destination_library_hours,
                                              Settings.scan[scan_destination_library_code]&.scan_schedule || Settings.scan.default.scan_schedule, after: steps[:scan_processed])

    if details
      steps
    else
      steps[:scan_delivered]
    end
  end
  # rubocop:enable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity

  def next_action_time(open_days, scheduled_times, after: time)
    action_times = Array(scheduled_times).flat_map do |scheduled_time|
      parsed_time = Time.zone.parse(scheduled_time)
      open_days.map { |day| day.change(hour: parsed_time.hour, min: parsed_time.min, sec: parsed_time.sec) }
    end

    action_times.select { |t| t == after || t.after?(after) }.min
  end

  def origin_library_code
    from&.paging_schedule_origin_library_code || @origin_library_code
  end

  def destination_library_code
    @destination_library_code ||= Settings.ils.pickup_destination_class.constantize.new(to).library_code || to
  end

  def origin_library_hours
    @origin_library_hours ||= LibraryHours.new(origin_library_code)
  end

  def destination_library_hours
    @destination_library_hours ||= LibraryHours.new(destination_library_code)
  end

  def destination_library_hours_next_business_day_after_delivery
    to_code = Settings.libraries[to] ? to : Folio::Types.service_points.find_by(code: to)&.library&.code
    LibraryHours.new(to_code).next_business_day(origin_library_next_business_day)
  end

  # Formatted estimate for delivery
  class Estimate
    def initialize(paging_schedule, as_of: Time.zone.now)
      @paging_schedule = paging_schedule
      @as_of = as_of
    end

    attr_reader :paging_schedule, :as_of

    def as_json(*)
      {
        date: estimated_delivery_day_to_destination,
        time: estimated_delivery_time_to_destination,
        text: to_s
      }
    end

    def to_s
      "#{I18n.l(estimated_delivery_day_to_destination, format: :long)}, #{estimated_delivery_time_to_destination}"
    end

    private

    def estimated_delivery_day_to_destination
      schedule_for_request.to_date
    end

    def estimated_delivery_time_to_destination
      return schedule_for_request.strftime('%-I:%M %p') if schedule_for_request.min.zero?

      (schedule_for_request.end_of_hour + 1.second).strftime('%-I:%M %p')
    end

    def schedule_for_request
      @schedule_for_request ||= paging_schedule.schedule_for_request
    end
  end

  class ScheduleNotFound < StandardError
  end
end
