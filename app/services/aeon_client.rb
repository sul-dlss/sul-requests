# frozen_string_literal: true

# Client for the Aeon API
class AeonClient
  class NotFoundError < StandardError; end
  class UnauthorizedError < StandardError; end

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
    default_handling_for(response:, klass: Aeon::User, not_found: nil)
  end

  # Fetch appointments for a user by their Aeon username
  # @param username [String] the user's Aeon username
  # @param context [Integer, nil] Determines whether to look at appointments for the user's researchers (optional)
  # @param pending_only [Boolean] Filters by appointments that have not started yet (optional)
  # @return [Array<Aeon::Request>]
  def appointments_for(username:, context: nil, pending_only: false)
    params = { context: context, pendingOnly: pending_only }
    response = get("Users/#{CGI.escape(username)}/requests", params: params)
    default_handling_for(response:, klass: Aeon::Appointment, not_found: [])
  end

  # Fetch requests for a user by their Aeon username
  # @param username [String] the user's Aeon username
  # @param active_only [Boolean] Filters by active Requests (optional)
  # @return [Array<Aeon::Request>]
  def requests_for(username:, active_only: false)
    response = get("Users/#{CGI.escape(username)}/requests", params: { activeOnly: active_only })
    default_handling_for(response:, klass: Aeon::Request, not_found: [])
  end

  private

  def default_handling_for(response:, klass:, not_found:) # rubocop:disable Metrics/MethodLength
    case response.status
    when 200
      parsed_response = parse_json(response)
      return parsed_response.map { |data| klass.from_dynamic(data) } if parsed_response.is_a?(Array)

      klass.from_dynamic(parsed_response)
    when 401
      raise UnauthorizedError
    when 404
      not_found
    else
      raise "Aeon API error: #{response.status}"
    end
  end

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
