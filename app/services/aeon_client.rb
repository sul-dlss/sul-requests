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

  def create_user(username:, auth_type: 'Default')
    response = post('Users', { username:, authType: auth_type, cleared: 'No' })

    handle_response(response, as_class: Aeon::User)
  end

  # Fetch requests for a user by their Aeon username
  # @param username [String] the user's Aeon username
  # @return [Array<Aeon::Request>]
  def requests_for(username:, active_only: false)
    response = get("Users/#{CGI.escape(username)}/requests", params: { activeOnly: active_only })

    handle_response(response, as_class: Aeon::Request, not_found: [])
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
      { op: 'replace', path: '/name', value: name },
      { op: 'replace', path: '/startTime', value: start_time.iso8601 },
      { op: 'replace', path: '/stopTime', value: stop_time.iso8601 }
    ]

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

  CreateRequestData = Data.define(:call_number, :ead_number, :item_author, :item_citation, :item_date, :item_info1, :item_info2,
                                  :item_info3, :item_info4, :item_info5, :item_subtitle, :item_title, :item_volume,
                                  :shipping_option, :site, :special_request, :username) do
    def as_json # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      {
        callNumber: call_number,
        eadNumber: ead_number,
        itemAuthor: item_author,
        itemCitation: item_citation,
        itemDate: item_date,
        itemInfo1: item_info1,
        itemInfo2: item_info2,
        itemInfo3: item_info3,
        itemInfo4: item_info4,
        itemInfo5: item_info5,
        itemSubTitle: item_subtitle,
        itemTitle: item_title,
        itemVolume: item_volume,
        shippingOption: shipping_option,
        site: site,
        specialRequest: special_request,
        username: username,
        webRequestForm: 'SUL Requests'
      }.compact
    end
  end

  # Submit an archives request to Aeon
  # @param username [String] the user's Aeon username, which is an email
  def create_request(aeon_payload)
    response = post('Requests/create', aeon_payload.as_json)

    handle_response(response, as_class: Aeon::Request)
  end

  def update_request(transaction_number:, status:)
    response = post("Requests/#{transaction_number}/route", { newStatus: status })

    handle_response(response, as_class: Aeon::Request)
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
