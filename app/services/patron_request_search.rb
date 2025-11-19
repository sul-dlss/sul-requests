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
    patron_request = search_date_range(PatronRequest, params)

    patron_request = patron_request.where(service_point_code: params['service_point_code']) if params['service_point_code']

    patron_request = filter_results(patron_request, params['request_type'], 'type')

    filter_results(patron_request, params['origin_library_code'], 'origin_library_code')
  end

  def search_date_range(search_list, params)
    return search_list unless params['start_date']

    start_date = Date.parse(params['start_date'])
    end_date = Date.parse(params['end_date'])
    patron_request.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
  end

  def filter_results(search_list, param, field)
    return search_list unless param

    search_list.select { |record| param.include?(record.public_send(field)) }
  end
end
