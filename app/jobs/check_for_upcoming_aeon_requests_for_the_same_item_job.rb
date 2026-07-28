# frozen_string_literal: true

##
# Rails Job to figure out which items are being reused in the reading room within a window.
class CheckForUpcomingAeonRequestsForTheSameItemJob < ApplicationJob
  def perform(upcoming_time: 14.days) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    # get all the upcoming appointments for SPEC
    upcoming_appointments = aeon_client.appointments(range: (1.day.ago)..(upcoming_time.from_now)).select do |appointment|
      appointment.reading_room.sites.include?('SPECUA')
    end
    appointment_ids = upcoming_appointments.map(&:id)
    # get the users that have those appointments (because there's no direct way to get the requests for a given appointment)
    usernames = upcoming_appointments.map(&:username).uniq
    users = usernames.filter_map { |username| Aeon::User.find_by(email_address: username) }
    # get the users' requests for those appointments (and get rid of items with the same appointment)
    requests = users.flat_map(&:requests).select { |request| appointment_ids.include?(request.appointment_id) }.uniq do |request|
      [request.appointment_id, request.item_number.presence || [request.call_number, request.item_volume]]
    end

    # select the requests for the same item (same callnumber + volume or same item number)
    grouped_requests = requests.group_by do |request|
      request.item_number.presence || [request.call_number, request.item_volume]
    end

    # send an email to the staff with the report of items that are likely in the reading room now and being re-used soon
    salient_requests = grouped_requests.select do |_, requests|
      requests.size > 1 && requests.any? do |r|
        r.appointment.start_time.before?(3.days.from_now)
      end
    end.values
    AeonMailer.repeated_requests(salient_requests).deliver_now
  end

  def aeon_client
    @aeon_client ||= AeonClient.new
  end
end
