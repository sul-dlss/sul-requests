# frozen_string_literal: true

# Calls FOLIO REST endpoints
class FolioClient
  DEFAULT_HEADERS = {
    accept: 'application/json, text/plain',
    content_type: 'application/json'
  }.freeze

  attr_reader :base_url

  def initialize(url: Settings.folio.okapi_url, tenant: Settings.folio.tenant)
    uri = URI.parse(url)

    @username = uri.user
    @password = uri.password
    @base_url = uri.dup.tap do |u|
      u.user = nil
      u.password = nil
    end.to_s

    @tenant = tenant
  end

  # Overridden so that we don't display password
  def inspect
    "#<#{self.class.name}:#{object_id}  @base_url=\"#{base_url}\">"
  end

  # Return the FOLIO user object given a sunetid
  # See https://s3.amazonaws.com/foliodocs/api/mod-users/p/users.html#users__userid__get
  def login_by_sunetid(sunetid)
    response = get_json('/users', params: { query: CqlQuery.new(username: sunetid).to_query })
    response.dig('users', 0)
  end

  # Return the FOLIO user object given a library id (e.g. barcode)
  # See https://s3.amazonaws.com/foliodocs/api/mod-users/p/users.html#users__userid__get
  def login_by_library_id(library_id)
    response = get_json('/users', params: { query: CqlQuery.new(barcode: library_id).to_query })
    response.dig('users', 0)
  end

  def user_info(user_id)
    get_json("/users/#{CGI.escape(user_id)}")
  end

  def patron_blocks(user_id)
    get_json("/automated-patron-blocks/#{user_id}")
  end

  # Defines the hold request to Folio
  # [String] pickup_location_id the UUID of the pickup location
  # [String] patron_comments
  # [Date] expiration_date
  HoldRequest = Data.define(:pickup_location_id, :patron_comments, :expiration_date) do
    def as_json
      {
        pickupLocationId: pickup_location_id,
        patronComments: patron_comments,
        expirationDate: expiration_date,
        requestDate: Time.now.utc.iso8601
      }
    end
  end

  # See https://s3.amazonaws.com/foliodocs/api/mod-patron/p/patron.html#patron_account__id__instance__instanceid__hold_post
  # @example client.create_instance_hold('562a5cb0-e998-4ea2-80aa-34ac2b536238',
  #                                      'cc3d8728-a6b9-45c4-ad0c-432873c3ae47',
  #                                      HoldRequest.new)
  # @param [String] user_id the UUID of the FOLIO user
  # @param [String] instance_id the UUID of the FOLIO instance
  # @param [HoldRequest] request
  def create_instance_hold(user_id, instance_id, request)
    response = post("/patron/account/#{user_id}/instance/#{instance_id}/hold", json: request.as_json)
    check_response(response, title: 'Hold request', context: { user_id:, instance_id:, **params })

    parse_json(response)
  end

  # See https://s3.amazonaws.com/foliodocs/api/mod-patron/p/patron.html#patron_account__id__item__itemid__hold_post
  # @example client.create_item_hold('562a5cb0-e998-4ea2-80aa-34ac2b536238',
  #                                  'd9097766-cc5d-5bb5-9173-8e883950380f',
  #                                  HoldRequest.new)
  # @param [String] user_id the UUID of the FOLIO user
  # @param [String] item_id the UUID of the FOLIO item
  # @param [HoldRequest] request
  def create_item_hold(user_id, item_id, request)
    response = post("/patron/account/#{user_id}/item/#{item_id}/hold", json: request.as_json)

    check_response(response, title: 'Hold request', context: { user_id:, item_id:, **params })

    parse_json(response)
  end

  def items_and_holdings(instance_id:)
    body = {
      instanceIds: [instance_id],
      skipSuppressedFromDiscoveryRecords: false
    }
    get_json('/inventory-hierarchy/items-and-holdings', method: :post, json: body)
  end

  def get_item(barcode)
    response = get_json('/item-storage/items', params: { query: CqlQuery.new(barcode:).to_query })

    response.dig('items', 0)
  end

  def get_service_point(code)
    response = get_json('/service-points', params: { query: CqlQuery.new(code:).to_query })

    response.dig('servicepoints', 0)
  end

  private

  def check_response(response, title:, context:)
    return if response.success?

    context_string = context.map { |k, v| "#{k}: #{v}" }.join(', ')
    raise "#{title} request for #{context_string} was not successful. " \
          "status: #{response.status}, #{response.body}"
  end

  def get(path, **kwargs)
    authenticated_request(path, method: :get, **kwargs)
  end

  def post(path, **kwargs)
    authenticated_request(path, method: :post, **kwargs)
  end

  def get_json(path, **kwargs)
    parse_json(get(path, **kwargs))
  end

  # @param [Faraday::Response] response
  # @raises [StandardError] if the response was not a 200
  # @return [Hash] the parsed JSON data structure
  def parse_json(response)
    return nil if response.body.empty?

    JSON.parse(response.body)
  end

  def session_token
    @session_token ||= begin
      response = request('/authn/login', json: { username: @username, password: @password }, method: :post)
      raise response.body unless response.status == 201

      response['x-okapi-token']
    end
  end

  def authenticated_request(path, method:, params: nil, headers: {}, json: nil)
    request(path, method:, params:, headers: headers.merge('x-okapi-token': session_token), json:)
  end

  def request(path, method:, headers: nil, params: nil, json: nil)
    connection.send(method, path, params, headers) do |req|
      req.body = json.to_json if json
    end
  end

  def connection
    @connection ||= Faraday.new(base_url) do |builder|
      builder.request :retry, max: 4, interval: 1, backoff_factor: 2
      default_headers.each do |k, v|
        builder.headers[k] = v
      end
    end
  end

  def default_headers
    DEFAULT_HEADERS.merge({ 'X-Okapi-Tenant': @tenant, 'User-Agent': 'SulRequests' })
  end
end
