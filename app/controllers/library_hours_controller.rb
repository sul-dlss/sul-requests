# frozen_string_literal: true

# Proxy for the library-hours API. The date picker probes this endpoint per
# visible month to fetch closure dates it should disable.
class LibraryHoursController < ApplicationController
  def closures # rubocop:disable Metrics/AbcSize
    from = month_start
    return head :bad_request unless from

    query = LibraryHoursApi.get(params[:library_slug], params[:location_slug], from: from.iso8601, to: from.end_of_month.iso8601)
    render json: { month: params[:month], unavailable_dates: query.closed_days.map { |hours| hours.day.iso8601 } }
  end

  private

  def month_start
    Time.zone.parse("#{params[:month]}-01")&.to_date
  rescue ArgumentError
    nil
  end
end
