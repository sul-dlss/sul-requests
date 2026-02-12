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
      Aeon::User.new(response.body)
    when 404
      raise NotFoundError, "No Aeon account found for #{username}"
    else
      raise "Aeon API error: #{response.status}"
    end
  end

  def create_user(username:, auth_type: 'Default')
    response = post('Users', { username:, authType: auth_type })

    case response.status
    when 201
      Aeon::User.new(response.body)
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
      response.body.map { |data| Aeon::Request.from_dynamic(data) }
    when 404
      []
    else
      raise "Aeon API error: #{response.status}"
    end
  end

  def appointments_for(username:, context: 'both', pending_only: true)
    response = get("Users/#{CGI.escape(username)}/appointments", params: { context: context, pendingOnly: pending_only })

    case response.status
    when 200
      response.body.map { |data| Aeon::Appointment.from_dynamic(data) }
    when 404
      []
    else
      raise "Aeon API error: #{response.status}"
    end
  end

  def create_appointment(username:, start_time:, end_time:, name:, reading_room_id:) # rubocop:disable Metrics/MethodLength
    response = post('Appointments', {
                      username:,
                      startTime: start_time.iso8601,
                      stopTime: end_time.iso8601,
                      name:,
                      readingRoomID: reading_room_id
                    })

    case response.status
    when 201
      Aeon::Appointment.from_dynamic(response.body)
    else
      raise "Aeon API error: #{response.status}"
    end
  end

  def cancel_appointment(appointment_id)
    response = delete("Appointments/#{appointment_id}")

    case response.status
    when 204, 404
      true
    else
      raise "Aeon API error: #{response.status}"
    end
  end

  def reading_rooms
    response = get('ReadingRooms')

    case response.status
    when 200
      response.body.map { |data| Aeon::ReadingRoom.from_dynamic(data) }
    else
      raise "Aeon API error: #{response.status}"
    end
  end

  private

  def get(path, params: nil)
    connection.get(path, params)
  end

  def post(path, body, **)
    connection.post(path, body, content_type: 'application/json', **)
  end

  def delete(path, params: nil)
    connection.delete(path, params:)
  end

  def connection
    @connection ||= Faraday.new(@base_url) do |builder|
      builder.request :json
      builder.request :retry, max: 4, interval: 1, backoff_factor: 2
      builder.response :json

      default_headers.each do |k, v|
        builder.headers[k] = v
      end
    end
  end

  def default_headers
    DEFAULT_HEADERS.merge({ 'X-AEON-API-KEY': @api_key })
  end
end
