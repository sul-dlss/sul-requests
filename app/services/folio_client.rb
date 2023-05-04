# frozen_string_literal: true

require 'http'

# Calls FOLIO REST endpoints
class FolioClient
  DEFAULT_HEADERS = {
    accept: 'application/json, text/plain',
    content_type: 'application/json'
  }.freeze

  attr_reader :base_url

  def initialize(url: ENV.fetch('OKAPI_URL'), tenant: 'sul')
    uri = URI.parse(url)

    @username = uri.user
    @password = uri.password
    @base_url = uri.dup.tap do |u|
      u.user = nil
      u.password = nil
    end.to_s

    @tenant = tenant
  end

  # Return the FOLIO user_id given a sunetid
  # See https://s3.amazonaws.com/foliodocs/api/mod-users/p/users.html#users__userid__get
  def lookup_user_id(sunetid)
    result = json_response('/users', params: { query: "username==\"#{sunetid}\"" })
    result.dig('users', 0, 'id')
  end

  # See https://s3.amazonaws.com/foliodocs/api/mod-patron/p/patron.html#patron_account__id__instance__instanceid__hold_post
  # @example client.create_instance_hold('jcoyne85', 'cc3d8728-a6b9-45c4-ad0c-432873c3ae47', '123d9cba-85a8-42e0-b130-c82e504c64d6')
  # @param [String] sunetid
  # @param [String] instance_id the UUID of the FOLIO instance
  # @param [String] pickup_location_id the UUID of the pickup locatio
  def create_instance_hold(sunetid, instance_id, pickup_location_id)
    user_id = lookup_user_id(sunetid)
    raise "No user_id for #{sunetid}" unless user_id

    response = post("/patron/account/#{user_id}/instance/#{instance_id}/hold",
                    json: {
                      requestDate: Time.now.utc.iso8601,
                      pickupLocationId: pickup_location_id
                    })
    return if response.status.success?

    raise "Hold request for user_id: #{user_id}, instance_id: #{instance_id}, " \
          "pickup_location_id: #{pickup_location_id} was not successful. status: #{response.status.code}, #{response.body}"
  end

  private

  def get(path, **kwargs)
    authenticated_request(path, method: :get, **kwargs)
  end

  def post(path, **kwargs)
    authenticated_request(path, method: :post, **kwargs)
  end

  def json_response(path, **kwargs)
    parse_json(get(path, **kwargs))
  end

  # @param [HTTP::Response] response
  # @raises [StandardError] if the response was not a 200
  # @return [Hash] the parsed JSON data structure
  def parse_json(response)
    raise response unless response.status.ok?
    return nil if response.body.empty?

    JSON.parse(response.body)
  end

  def session_token
    @session_token ||= begin
      response = request('/authn/login', json: { username: @username, password: @password }, method: :post)
      raise response.body unless response.status.created?

      response['x-okapi-token']
    end
  end

  def authenticated_request(path, headers: {}, **other)
    request(path, headers: headers.merge('x-okapi-token': session_token), **other)
  end

  def request(path, headers: {}, method: :get, **other)
    HTTP
      .headers(default_headers.merge(headers))
      .request(method, base_url + path, **other)
  end

  def default_headers
    DEFAULT_HEADERS.merge({ 'X-Okapi-Tenant': @tenant, 'User-Agent': 'SulRequests' })
  end
end
