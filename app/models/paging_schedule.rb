# frozen_string_literal: true

###
#  PagingSchedule takes a requested item and can
#  read the paging schedule configuration and estimate a date of arrival.
###
class PagingSchedule
  attr_reader :from, :to, :time, :library_hours

  def initialize(from:, to:, time: nil, library_code: nil, library_hours: LibraryHours.new)
    @from = from
    @to = to
    @origin_library_code = library_code
    @time = time || Time.zone.now
    @library_hours = library_hours
  end

  delegate :business_days_for, to: :library_hours

  def valid?(date)
    scheduled_date = schedule_for_request[:completed].to_date

    scheduled_date >= date && library_hours.open?(destination_library_code, on: date)
  rescue ScheduleNotFound
    false
  end

  def earliest_delivery_estimate
    Estimate.new(self, as_of: time)
  end

  def schedule_for_request # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    # We don't estimate schedules for items that patrons have requested to be sent via ILLiad
    raise ScheduleNotFound if from&.pages_prefer_to_send_via_illiad?

    @schedule_for_request ||= begin
      steps = { meta: { from: origin_library_code, to: to }, request: time }

      # All requests start with physically pulling items from the shelf
      shelf_pull_for_origin_library(steps)

      # Next, items need to transit to the destination library (directly, via mailroom, or via courier)
      direct_delivery_to_destination_library(steps)
      courier_delivery_to_green(steps)
      mailroom_processing_from_origin_library(steps)
      courier_delivery_to_branch(steps)

      if scan?
        steps[:meta][:via] = destination_library_code

        # Scanning needs some processing time once it arrives to do the actual work
        scan_processing_time(steps)
      else
        # Once at the destination library, some staff processing needs to happen before it's available
        staff_processing_at_destination_library(steps)

        # ... and the library has to be open for the patron to pick it up
        material_made_available_to_the_patron(steps)
      end

      steps[:completed] = steps[:scan_delivered] || steps[:available_at_destination]

      steps
    end
  end

  private

  # Library code the material is originating from (often the FOLIO library of the location, but there are some exceptions...)
  def origin_library_code
    from&.paging_schedule_origin_library_code || @origin_library_code
  end

  # Library code the material is being physically sent to
  def destination_library_code
    return scan_destination_library_code if scan?

    @destination_library_code ||= Settings.ils.pickup_destination_class.constantize.new(to).library_code || to
  end

  def scan?
    to == 'SCAN'
  end

  # Library that handles scanning the material
  def scan_destination_library_code
    return unless scan?

    from&.details&.[]('scanServicePointCode') || 'GREEN'
  end

  # Does the material bypass the mailroom and go directly to the destination library (because it's already there,
  # or staff just walk it over)
  def directly_delivered?
    origin_library_code == destination_library_code || (origin_library_code == 'MEDIA-CENTER' && destination_library_code == 'GREEN')
  end

  # Business days for mailroom operations (currently pretending it's just Green's hours)
  # TODO: consider adding library hours for mailroom operations?
  def business_days_for_mailroom_operations(after: time)
    business_days_for('GREEN', after: after).reject(&:on_weekend?)
  end

  # TODO: check assumption that scanning usually happens on weekdays
  def scan_destination_library_hours(after: time)
    business_days_for(scan_destination_library_code, after: after).reject(&:on_weekend?)
  end

  # Figure out when the next action occurs (e.g. on a day when the location is open, at some scheduled time)
  def next_action_time(open_days, scheduled_times, after: time)
    action_times = Array(scheduled_times).flat_map do |scheduled_time|
      parsed_time = Time.zone.parse(scheduled_time)
      open_days.map { |day| day.change(hour: parsed_time.hour, min: parsed_time.min, sec: parsed_time.sec) }
    end

    action_times.select { |t| t == after || t.after?(after) }.min
  end

  ##
  # Workflow steps
  ##

  # Step 1: Physically pulling material from the shelves at the origin library
  def shelf_pull_for_origin_library(steps, after: time)
    pull_schedule = Array(Settings.library_pull_schedule[origin_library_code])
    origin_open_days = business_days_for(origin_library_code, after: after)
    steps[:shelf_pull] = next_action_time(origin_open_days, pull_schedule, after: after)
  end

  # Step 2a: Some shelf pulls are immediately available at the destination library without further processing
  #          (e.g. because the origin and destination are the same library)
  def direct_delivery_to_destination_library(steps)
    return unless directly_delivered?

    steps[:ready_for_mailroom_pickup] = steps[:shelf_pull]
    steps[:delivered_to_destination] = steps[:shelf_pull]
  end

  # Step 2b: Shelf-pulls from MARINE-BIO need to get couriered to the Green mailroom for processing
  def courier_delivery_to_green(steps)
    return if steps[:delivered_to_destination].present?
    return unless origin_library_code == 'MARINE-BIO'

    # The MARINE-BIO courier drops material off at Green on Tuesdays and Thursdays at noon
    steps[:courier_delivery_to_green] = [steps[:shelf_pull].next_occurring(:tuesday),
                                         steps[:shelf_pull].next_occurring(:thursday)].min.change(hour: 12, min: 0, sec: 0)
    steps[:ready_for_mailroom_pickup] = steps[:courier_delivery_to_green]
  end

  # Step 2c: If the material wasn't directly delivered, the mailroom needs to pick it up from origin,
  #          sort it, and deliver it to the destination library.
  def mailroom_processing_from_origin_library(steps) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    return if steps[:delivered_to_destination].present?

    # add a little time for staff packing?
    steps[:ready_for_mailroom_pickup] ||= steps[:shelf_pull].advance(minutes: 5)

    mailroom_open_days = business_days_for_mailroom_operations(after: steps[:ready_for_mailroom_pickup])
    steps[:mailroom_pickup] =
      next_action_time(mailroom_open_days,
                       Settings.mailroom[origin_library_code] || Settings.mailroom.default, after: steps[:ready_for_mailroom_pickup])

    mailroom_open_days = business_days_for_mailroom_operations(after: steps[:mailroom_pickup])
    steps[:mailroom_sort] = next_action_time(mailroom_open_days, Settings.mailroom.sorted_by, after: steps[:mailroom_pickup])

    return if destination_library_code == 'MARINE-BIO'

    mailroom_open_days = business_days_for_mailroom_operations(after: steps[:mailroom_sort])
    destination_delivery_open_days = business_days_for(destination_library_code, after: steps[:mailroom_sort])
    steps[:mailroom_delivery] = next_action_time(mailroom_open_days & destination_delivery_open_days,
                                                 Settings.mailroom[destination_library_code], after: steps[:mailroom_sort])

    steps[:delivered_to_destination] = steps[:mailroom_delivery]
  end

  # Step 2d: ... but the MARINE-BIO courier needs to pick it up from the mailroom and deliver it there
  def courier_delivery_to_branch(steps) # rubocop:disable Metrics/AbcSize
    return if steps[:delivered_to_destination].present?
    return unless destination_library_code == 'MARINE-BIO'

    # The MARINE-BIO courier goes to Hopinks on Mondays (pickup only), Wednesdays, and Fridays at 5pm
    steps[:courier_delivery_to_mar] = [steps[:mailroom_sort].next_occurring(:wednesday),
                                       steps[:mailroom_sort].next_occurring(:friday)].min

    destination_delivery_open_days = business_days_for(destination_library_code, after: steps[:courier_delivery_to_mar])
    steps[:delivered_to_destination] = next_action_time(destination_delivery_open_days,
                                                        Settings.mailroom[destination_library_code], after: steps[:courier_delivery_to_mar])
  end

  # Step 3a + b + c: Once the material is delivered to the destination library, there's some staff processing that happens
  #         before it's ready for pickup
  def staff_processing_at_destination_library(steps) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    # Each location needs a little bit of time to check in the material after delivery
    checkin_processing_hours = Settings.hold_shelf_staff_checkin_delay_hours[destination_library_code] ||
                               Settings.hold_shelf_staff_checkin_delay_hours.default
    steps[:staff_processed] = steps[:delivered_to_destination].advance(hours: checkin_processing_hours)

    steps[:ready] = steps[:staff_processed]

    # Some (mainly special collections) locations also need some minimum processing days before the material is ready for pickup
    minimum_processing_time = Settings.minimum_library_processing_days[origin_library_code]&.days
    if minimum_processing_time && (steps[:staff_processed] - steps[:shelf_pull]) < minimum_processing_time
      destination_business_days = business_days_for(destination_library_code, after: steps[:shelf_pull])
      steps[:ready] =
        destination_business_days[Settings.minimum_library_processing_days[origin_library_code]].change(hour: steps[:staff_processed].hour)
    end

    # And some locations make the material available only at certain times
    if Settings.library_staff_checkin_schedule[destination_library_code]
      destination_open_days = business_days_for(destination_library_code, after: steps[:ready])

      steps[:ready] = next_action_time(destination_open_days,
                                       Settings.library_staff_checkin_schedule[destination_library_code],
                                       after: steps[:ready])
    end

    steps[:ready]
  end

  # Step 4: Adjust the estimated availability time to make sure the library is actually open so the patron can pick it up
  def material_made_available_to_the_patron(steps)
    after_time = steps[:ready]

    # check destination opening hours, or punt to the next business day
    destination_library_hours = library_hours.next_schedule_for(destination_library_code, after: after_time)
    # If the material arrives at the destination (and the destination is meaningfully open) we can make it available the same day...
    still_open_on_current_business_day = destination_library_hours.find { |d| d.cover?(after_time + 15.minutes) }

    steps[:available_at_destination] = if still_open_on_current_business_day
                                         after_time
                                       else
                                         # Otherwise delay the estimate to the next opening time
                                         destination_library_hours.map(&:begin).find { |d| d.after?(after_time) } || after_time
                                       end
  end

  # SCAN-specific processing time: adding scan processing days and delivery schedule
  def scan_processing_time(steps) # rubocop:disable Metrics/AbcSize
    scan_processing_time = (
      Settings.scan[scan_destination_library_code]&.scan_processing_days || Settings.scan.default.scan_processing_days
    ).days
    steps[:scan_processed] = steps[:delivered_to_destination] + scan_processing_time

    scheduled_scan_times = Settings.scan[scan_destination_library_code]&.scan_schedule || Settings.scan.default.scan_schedule
    steps[:scan_delivered] =
      next_action_time(scan_destination_library_hours(after: steps[:scan_processed]), scheduled_scan_times, after: steps[:scan_processed])
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

    # Round up the scheduled delivery time to the next hour
    def estimated_delivery_time_to_destination
      return schedule_for_request.strftime('%-I:%M %p') if schedule_for_request.min.zero?

      (schedule_for_request.end_of_hour + 1.second).strftime('%-I:%M %p')
    end

    def schedule_for_request
      @schedule_for_request ||= paging_schedule.schedule_for_request[:completed]
    end
  end

  class ScheduleNotFound < StandardError
  end
end
