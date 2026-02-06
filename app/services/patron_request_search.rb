# frozen_string_literal: true

# Search through PatronRequest fields with provided parameters
class PatronRequestSearch
  def self.call(...)
    new(...).call
  end

  def initialize(params)
    @params = params
  end

  attr_reader :params

  def call
    patron_request = PatronRequest
    patron_request = search_request_type(patron_request)
    patron_request = search_date_range(patron_request)
    patron_request = search_origin_library(patron_request)
    search_destination_service_point(patron_request)
  end

  def search_date_range(patron_request)
    return patron_request unless params['start_date']

    start_date = Date.parse(params['start_date'])
    end_date = Date.parse(params['end_date'])
    patron_request.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
  end

  def search_origin_library(patron_request)
    return patron_request unless params['origin_library_code']

    patron_request.where(origin_location_code: params['origin_library_code'].flat_map do |code|
      Folio::Types.libraries.find_by(code: code)&.locations&.map(&:code)
    end)
  end

  def search_destination_service_point(patron_request)
    return patron_request unless params['service_point_code']

    patron_request.where(service_point_code: params['service_point_code'])
  end

  def search_request_type(patron_request)
    return patron_request unless params['request_type']

    patron_request.where(display_type: params['request_type'])
  end
end
