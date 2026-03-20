# frozen_string_literal: true

# Client for the Aeon API
class AeonClient
  class ApiError < StandardError; end
  class NotFoundError < ApiError; end

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

    handle_response(response, as_class: Aeon::User, not_found: nil).tap do |user|
      raise NotFoundError, "No Aeon account found for #{username}" unless user
    end
  end

  def create_user(user_data: {})
    response = post('Users', user_data.as_json)

    handle_response(response, as_class: Aeon::User)
  end

  # Fetch requests for a user by their Aeon username
  # @param username [String] the user's Aeon username
  # @return [Array<Aeon::Request>]
  def requests_for(username:, active_only: false)
    response = get("Users/#{CGI.escape(username)}/requests", params: { activeOnly: active_only })

    handle_response(response, as_class: Aeon::Request, not_found: [])
  end

  # Submit a new request to Aeon
  # @param aeon_payload [Hash]
  def create_request(aeon_payload)
    response = post('Requests/create', aeon_payload.as_json)

    handle_response(response, as_class: Aeon::Request)
  end

  # Submit a request patch to Aeon
  # @param aeon_payload [Hash]
  def update_request(transaction_number, aeon_payload)
    response = patch("Requests/#{transaction_number}", aeon_payload)

    handle_response(response, as_class: Aeon::Request)
  end

  def update_request_route(transaction_number:, status:)
    response = post("Requests/#{transaction_number}/route", { newStatus: status })

    handle_response(response, as_class: Aeon::Request)
  end

  def appointments_for(username:, context: 'both', pending_only: true)
    response = get("Users/#{CGI.escape(username)}/appointments", params: { context: context, pendingOnly: pending_only })

    handle_response(response, as_class: Aeon::Appointment, not_found: [])
  end

  def create_appointment(username:, start_time:, stop_time:, name:, reading_room_id:)
    response = post('Appointments', {
                      username:,
                      startTime: start_time.iso8601,
                      stopTime: stop_time.iso8601,
                      name:,
                      readingRoomID: reading_room_id
                    })

    handle_response(response, as_class: Aeon::Appointment)
  end

  def cancel_appointment(appointment_id)
    response = delete("Appointments/#{appointment_id}")

    case response.status
    when 204, 404
      true
    else
      raise ApiError, "Aeon API error: #{response.status}"
    end
  end

  def update_appointment(appointment_id, name:, start_time:, stop_time:)
    json_patch = [
      ({ op: 'replace', path: '/name', value: name } if name),
      { op: 'replace', path: '/startTime', value: start_time.iso8601 },
      { op: 'replace', path: '/stopTime', value: stop_time.iso8601 }
    ].compact

    response = patch("Appointments/#{appointment_id}", json_patch)

    handle_response(response, as_class: Aeon::Appointment)
  end

  def available_appointments(reading_room_id:, date:, include_next_available: false)
    response = get("ReadingRooms/#{reading_room_id}/AvailableAppointments/#{date.iso8601}",
                   params: { getNextAvailable: include_next_available })

    handle_response(response, as_class: Aeon::AvailableAppointment, not_found: [])
  end

  def reading_rooms
    response = get('ReadingRooms')

    handle_response(response, as_class: Aeon::ReadingRoom, not_found: [])
  end

  def find_queue(id:, type:)
    return unless id && type

    queues.find { |q| q.type == type && q.id == id }
  end

  def queues
    cached = Rails.cache.read('aeon/queues')
    return cached if cached

    response = get('Queues')
    handle_response(response) { |body| body.map { |data| Aeon::Queue.from_dynamic(data['queue']) } }.tap do |queues|
      Rails.cache.write('aeon/queues', queues, expires_in: 1.hour) if queues
    end
  end

  UserData = Data.define(:address, :address2, :city, :country, :email_address, :first_name, :last_name,
                         :phone, :sso, :state_or_province, :zip_code) do
    def omission = '…'

    def as_json # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      {
        address: address&.truncate(50, omission:),
        address2: address2&.truncate(50),
        authType: sso ? 'Default' : 'Aeon',
        city: city&.truncate(50, omission:),
        cleared: 'No',
        country: country&.truncate(50, omission:),
        eMailAddress: email_address&.truncate(100, omission:),
        firstName: first_name&.truncate(50),
        lastName: last_name&.truncate(50),
        phone: phone&.truncate(50, omission:),
        state_or_province: state_or_province&.truncate(50, omission:),
        username: email_address&.truncate(100, omission:),
        zip_code: zip_code&.truncate(50, omission:)
      }.compact
    end

    def self.with_defaults
      new(
        address: nil, address2: nil, city: nil, country: nil, email_address: nil,
        first_name: nil, last_name: nil, phone: nil, sso: false, state_or_province: nil, zip_code: nil
      )
    end
  end

  private

  def get(path, params: nil)
    connection.get(path, params)
  end

  def post(path, body, **)
    connection.post(path, body, content_type: 'application/json', **)
  end

  def patch(path, body, **)
    connection.patch(path, body, content_type: 'application/json', **)
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

  def handle_response(faraday_response, as_class: nil, not_found: nil) # rubocop:disable Metrics/MethodLength
    if faraday_response.success?
      body = faraday_response.body
      return yield body unless as_class

      if body.is_a?(Array)
        Array.wrap(body).map { |data| as_class.from_dynamic(data) }
      else
        as_class.from_dynamic(body)
      end
    elsif faraday_response.status == 404
      not_found
    else
      raise ApiError, "Aeon API error: #{faraday_response.status}"
    end
  end
end
