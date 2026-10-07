# frozen_string_literal: true

# Proxy for the library-hours API. The date picker probes this endpoint per
# visible month to fetch closure dates it should disable.
class LibraryHoursController < ApplicationController
  before_action :load_data

  def closures
    render json: {
      from: date_param.beginning_of_month.iso8601,
      until: date_param.end_of_month.iso8601,
      unavailable_dates: @data.closed_days.map do |hours|
        hours.day.iso8601
      end
    }
  end

  private

  def load_data
    @data = LibraryHoursApi.get(params.expect(:library_slug), params.expect(:location_slug),
                                from: date_param.beginning_of_month.iso8601,
                                to: date_param.end_of_month.iso8601)
  end

  def date_param
    @date_param ||= Time.zone.strptime(params.expect(:month), '%Y-%m')&.to_date
  rescue ArgumentError
    raise ActionController::BadRequest, 'Invalid month format'
  end
end
