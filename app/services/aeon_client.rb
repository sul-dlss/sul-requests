# frozen_string_literal: true

# Client for the Aeon API
class AeonClient
  class NotFoundError < StandardError; end

  DEFAULT_HEADERS = {
    accept: 'application/json'
  }.freeze

  def initialize(url: Settings.aeon.api_url, api_key: Settings.aeon.api_key)
    @base_url = url
    @api_key = api_key
  end

  def inspect
    "#<#{self.class.name}:#{object_id} @base_url=\"#{@base_url}\">"
  end

  def find_user(username:)
    response = get("Users/#{CGI.escape(username)}")
    case response.status
    when 200
      Aeon::User.new(parse_json(response))
    when 404
      raise NotFoundError, "No Aeon account found for #{username}"
    else
      raise "Aeon API error: #{response.status}"
    end
  end

  # Fetch requests for a user by their Aeon username
  # @param username [String] the user's Aeon username
  # @return [Array<Aeon::Request>]
  def requests_for(username:, active_only: false)
    response = get("Users/#{CGI.escape(username)}/requests", params: { activeOnly: active_only })

    case response.status
    when 200
      parse_json(response).map { |data| Aeon::Request.from_dynamic(data) }
    when 404
      []
    else
      raise "Aeon API error: #{response.status}"
    end
  end

  private

  def get(path, params: nil)
    connection.get(path, params)
  end

  def get_json(path, **)
    parse_json(get(path, **))
  end

  def parse_json(response)
    return nil if response.body.empty?

    JSON.parse(response.body)
  end

  def connection
    @connection ||= Faraday.new(@base_url) do |builder|
      builder.request :retry, max: 4, interval: 1, backoff_factor: 2
      default_headers.each do |k, v|
        builder.headers[k] = v
      end
    end
  end

  def default_headers
    DEFAULT_HEADERS.merge({ 'X-AEON-API-KEY': @api_key })
  end
end
