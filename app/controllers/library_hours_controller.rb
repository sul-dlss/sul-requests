# frozen_string_literal: true

# Proxy for using the LibraryHoursApi
class LibraryHoursController < ApplicationController
  def closures
    query = LibraryHoursApi.get(params['library_slug'], params['location_slug'], month_query_params)
    render json: { month: params[:month], unavailable_dates: query.closed_days.map { |hours| hours.day.iso8601 } }
  end

  def month_query_params
    from = Time.zone.parse("#{params[:month]}-01").to_date
    { from: from.iso8601, to: from.end_of_month.iso8601 }
  end
end
