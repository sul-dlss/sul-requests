# frozen_string_literal: true

require 'json'

# API for retrieving the current location from a barcode via Symphony Web Services
class SymphonyCurrLocRequest
  include ActiveModel::Model # allows initialization with a hash of attributes

  attr_accessor :barcode

  def current_location
    return '' if json.empty?

    json['fields']['currentLocation']['key']
  rescue NoMethodError => e
    Rails.logger.warn("currentLocation not available for #{barcode}; failed with: #{e}")
    return ''
  end

  private

  def response
    @response ||= faraday_conn_w_req_headers.get
    return empty_response(@response.body) unless @response.success?

    @response
  rescue Faraday::Error::ConnectionFailed => e
    empty_response(e)
  end

  def json
    return {} unless response.success?

    @json ||= JSON.parse(response.body)
  rescue JSON::ParserError => e
    Rails.logger.warn("Couldn't parse JSON from #{url}: #{e}")
    {}
  end

  BASE_URL = "#{Settings.symphony_web_services.base_url}#{Settings.symphony_web_services.curr_loc_path}"
  QUERY_STR = { includeFields: 'currentLocation' }.to_query.freeze

  def url
    @url ||= "#{BASE_URL}#{ERB::Util.url_encode(barcode)}?#{QUERY_STR}"
  end

  def empty_response(error = nil)
    Rails.logger.warn("HTTP GET for #{url} failed with: #{error}")
    NullResponse.new
  end

  def faraday_conn_w_req_headers
    Faraday.new(url: url) do |req|
      req.adapter Faraday.default_adapter
      # need the below for symws catalog/item/barcode
      req.headers['x-sirs-clientID'] = 'DS_CLIENT'
      req.headers['sd-originating-app-id'] = 'requests'
      req.headers['SD-Preferred-Role'] = 'GUEST'
    end
  end
end
