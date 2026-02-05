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
    patron_request = search_date_range(patron_request)
    patron_request = search_origin_library(patron_request)
    patron_request = search_destination_service_point(patron_request)
    search_request_type(patron_request)
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

  def search_request_type(patron_request) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    return patron_request unless params['request_type']

    filtered_request = patron_request.where(request_type: params['request_type'].flat_map do |type|
      case type
      when 'Mediated page'
        ['mediated', 'mediated/approved', 'mediated/done']
      when 'Hold', 'Recall', 'Page'
        'pickup'
      else
        type.downcase
      end
    end)

    fulfillment_types = []

    fulfillment_types << nil if params['request_type']&.include?('Page')
    fulfillment_types << 'hold' if params['request_type']&.include?('Hold')
    fulfillment_types << 'recall' if params['request_type']&.include?('Recall')
    filtered_request = filtered_request.where(fulfillment_type: fulfillment_types) if fulfillment_types.length.positive?

    filtered_request
  end
end
