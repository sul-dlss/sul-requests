# frozen_string_literal: true

# Client for the Aeon API
class AeonClient
  class NotFoundError < StandardError; end

  DEFAULT_HEADERS = {
    accept: 'application/json'
  }.freeze

  # Maps from the value in EAD to Aeon's valid site codes
  REPOSITORY_TO_SITE_CODE = {
    'Department of Special Collections and University Archives' => 'SPECUA',
    'Archive of Recorded Sound' => 'ARS',
    'East Asia Library' => 'EASTASIA'
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

  def create_appointment(username:, start_time:, stop_time:, name:, reading_room_id:) # rubocop:disable Metrics/MethodLength
    response = post('Appointments', {
                      username:,
                      startTime: start_time.iso8601,
                      stopTime: stop_time.iso8601,
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

  def update_appointment(appointment_id, name:, start_time:, stop_time:) # rubocop:disable Metrics/MethodLength
    json_patch = [
      { op: 'replace', path: '/name', value: name },
      { op: 'replace', path: '/startTime', value: start_time.iso8601 },
      { op: 'replace', path: '/stopTime', value: stop_time.iso8601 }
    ]

    response = patch("Appointments/#{appointment_id}", json_patch)

    case response.status
    when 200, 204
      Aeon::Appointment.from_dynamic(response.body)
    else
      raise "Aeon API error: #{response.status}"
    end
  end

  def available_appointments(reading_room_id:, date:, include_next_available: false)
    response = get("ReadingRooms/#{reading_room_id}/AvailableAppointments/#{date.iso8601}",
                   params: { getNextAvailable: include_next_available })

    case response.status
    when 200
      response.body.map { |data| Aeon::AvailableAppointment.from_dynamic(data) }
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

  def find_queue(id:, type:)
    return unless id && type

    queues.find { |q| q.type == type && q.id == id }
  end

  def queues
    cached = Rails.cache.read('aeon/queues')
    return cached if cached

    response = get('Queues')
    case response.status
    when 200
      queues = response.body.map { |data| Aeon::Queue.from_dynamic(data['queue']) }
      # Queues are the valid states a request can be in. This information is critical
      # for nearly every request operation. They are generally static, but are
      # updatable by library staff via the Aeon customization manager.
      Rails.cache.write('aeon/queues', queues, expires_in: 1.hour)
      queues
    else
      raise "Aeon API error: #{response.status}"
    end
  end
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/Metrics/ParameterLists

  # Submit an archives request to Aeon
  # @param username [String] the user's Aeon username, which is an email
  def submit_archives_request(username:, title:, author: nil, call_number: nil, volume: nil,
                              aeon_link: nil, shipping_option: nil, identifier: nil,
                              repository: nil)
    aeon_payload = {
      username:,
      itemTitle: title,
      itemAuthor: author,
      callNumber: call_number,
      itemVolume: volume,
      itemInfo1: aeon_link,
      shippingOption: shipping_option,
      eadNumber: identifier,
      site: map_repository_to_site_code(repository),
      webRequestForm: 'SUL Requests'
    }.compact # Remove nil values

    response = post('Requests/create', aeon_payload)

    case response.status
    when 201
      response.body
    else
      raise "Aeon API error: #{response.status} - #{response.body}"
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/Metrics/ParameterLists

  def delete_request(transaction_number:)
    post("Requests/#{transaction_number}/route", { newStatus: 'Cancelled by User' })
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

  def map_repository_to_site_code(repository)
    return nil unless repository

    # TODO: Fallback to SPECUA? Other logic?
    REPOSITORY_TO_SITE_CODE[repository] || 'SPECUA'
  end
end
