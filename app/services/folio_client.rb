# frozen_string_literal: true

# Calls FOLIO REST endpoints
class FolioClient
  class IlsError < StandardError; end

  DEFAULT_HEADERS = {
    accept: 'application/json, text/plain',
    content_type: 'application/json'
  }.freeze

  # Handle error responses coming back from FOLIO
  class Error < StandardError
    attr_reader :errors

    def initialize(msg, errors = {})
      super(msg)
      @errors = errors
    end
  end

  attr_reader :base_url

  delegate :service_points, to: :folio_graphql_client

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

  # Login by barcode or university ID, trying barcode first
  # TODO: remove once we're no longer using barcodes for auth
  def login_by_barcode_or_university_id(barcode_or_id, pin)
    login_by_barcode(barcode_or_id, pin) || login_by_university_id(barcode_or_id, pin)
  end

  # Find the user by barcode and validate their PIN, returning the user
  def login_by_barcode(barcode, pin)
    user = find_user_by_barcode(barcode) || find_user_by_legacy_barcode(barcode)

    return if user.blank?

    user if validate_patron_pin(user['id'], pin)
  end

  # Find the user by university ID and validate their PIN, returning the user
  def login_by_university_id(university_id, pin)
    user = find_user_by_university_id(university_id)
    user if validate_patron_pin(user['id'], pin)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Find the user by sunetid and return them; auth handled by Shibboleth
  def login_by_sunetid(sunetid)
    find_user_by_sunetid(sunetid)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Find a Folio::Patron by barcode or university ID, trying barcode first
  # TODO: remove once we're no longer using barcodes for auth
  def find_patron_by_barcode_or_university_id(barcode_or_id)
    find_patron_by_barcode(barcode_or_id) || find_patron_by_university_id(barcode_or_id)
  end

  # Find a Folio::Patron by barcode
  def find_patron_by_barcode(barcode)
    user = find_user_by_barcode(barcode) || find_user_by_legacy_barcode(barcode)

    if user.blank?
      Honeybadger.notify("Unable to find patron via barcode: #{barcode}")
      return
    end

    Folio::Patron.new(user)
  end

  # Find a Folio::Patron by university ID
  def find_patron_by_university_id(university_id)
    Folio::Patron.new(find_user_by_university_id(university_id))
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify("Unable to find patron via university id: #{university_id}")
    nil
  end

  # Find a Folio::Patron by sunetid
  def find_patron_by_sunetid(sunetid)
    Folio::Patron.new(find_user_by_sunetid(sunetid))
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify("Unable to find patron via sunetid: #{sunetid}")
    nil
  end

  # Find a Folio::Patron by ID
  def find_patron_by_id(user_id)
    Folio::Patron.new(find_user_by_id(user_id))
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify("Unable to find patron via id: #{user_id}")
    nil
  end

  # Validate a pin for a user
  # https://s3.amazonaws.com/foliodocs/api/mod-users/p/patronpin.html#patron_pin_verify_post
  # @param [String] user_id the UUID of the user in FOLIO
  # @param [String] pin
  # @return [Boolean] true when successful
  def validate_patron_pin(user_id, pin)
    response = post('/patron-pin/verify', json: { id: user_id, pin: })
    case response.status
    when 200
      true
    when 422
      false
    else
      check_response(response, title: 'Validate pin', context: { user_id: })
    end
  end

  # Assign a patron a new PIN using a token that identifies them
  # https://s3.amazonaws.com/foliodocs/api/mod-users/p/patronpin.html#patron_pin_post
  # @param [String] token the reset token
  # @param [String] new_pin the new PIN to assign
  def change_pin(token, new_pin)
    user_id = crypt.decrypt_and_verify(token)
    # expired tokens evaluate to nil; we want to raise an error instead
    raise ActiveSupport::MessageEncryptor::InvalidMessage unless user_id

    response = post('/patron-pin', json: { id: user_id, pin: new_pin })
    check_response(response, title: 'Assign pin', context: { user_id: })
  end

  def proxies(**args)
    response = get_json('/proxiesfor', params: { query: CqlQuery.new(**args).to_query })

    response['proxiesFor']
  end

  def patron_blocks(user_id)
    get_json("/automated-patron-blocks/#{user_id}")
  end

  # Defines the hold request data for Folio
  # [String] pickup_location_id the UUID of the pickup location
  # [String] patron_comments
  # [Date] expiration_date
  HoldRequestData = Data.define(:pickup_location_id, :patron_comments, :expiration_date) do
    def as_json
      {
        pickupLocationId: pickup_location_id,
        patronComments: patron_comments,
        expirationDate: expiration_date,
        requestDate: Time.now.utc.iso8601
      }
    end
  end

  def okapi_version
    @okapi_version ||= begin
      response = get('/_/version')
      check_response(response, title: 'Okapi version', context: {})
      # response.body is a string
      response.body
    end
  end

  CirculationRequestData = Data.define(:request_level, :request_type, :instance_id, :item_id, :holdings_record_id,
                                       :requester_id, :proxy_user_id, :fulfillment_preference, :pickup_service_point_id,
                                       :patron_comments, :request_expiration_date) do
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def as_json
      {
        requestLevel: request_level,
        requestType: request_type,
        instanceId: instance_id,
        itemId: item_id,
        holdingsRecordId: holdings_record_id,
        requesterId: requester_id,
        proxyUserId: (proxy_user_id unless proxy_user_id == requester_id),
        requestDate: Time.zone.now.utc.iso8601,
        pickupServicePointId: pickup_service_point_id,
        patronComments: patron_comments,
        requestExpirationDate: request_expiration_date,
        fulfillmentPreference: fulfillment_preference
      }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end

  def circulation_request_policy(item_type_id:, loan_type_id:, patron_type_id:, location_id:)
    response = get('/circulation/rules/request-policy', params: { item_type_id:, loan_type_id:, patron_type_id:, location_id: }.as_json)
    check_response(response, title: 'Request policy', context: { item_type_id:, loan_type_id:, patron_type_id:, location_id: })

    parse_json(response).fetch('requestPolicyId', nil)
  end

  # @param [HoldRequestData] request_data
  def create_circulation_request(request_data)
    response = post('/circulation/requests', json: request_data.as_json)
    check_response(response, title: 'Hold request', context: request_data.as_json)
    parse_json(response)
  end

  # See https://s3.amazonaws.com/foliodocs/api/mod-patron/p/patron.html#patron_account__id__instance__instanceid__hold_post
  # @example client.create_instance_hold('562a5cb0-e998-4ea2-80aa-34ac2b536238',
  #                                      'cc3d8728-a6b9-45c4-ad0c-432873c3ae47',
  #                                      HoldRequestData.new)
  # @param [String] user_id the UUID of the FOLIO user
  # @param [String] instance_id the UUID of the FOLIO instance
  # @param [HoldRequestData] request_data
  def create_instance_hold(user_id, instance_id, request_data)
    response = post("/patron/account/#{user_id}/instance/#{instance_id}/hold", json: request_data.as_json)
    check_response(response, title: 'Hold request', context: { user_id:, instance_id: })

    parse_json(response)
  end

  # See https://s3.amazonaws.com/foliodocs/api/mod-patron/p/patron.html#patron_account__id__item__itemid__hold_post
  # @example client.create_item_hold('562a5cb0-e998-4ea2-80aa-34ac2b536238',
  #                                  'd9097766-cc5d-5bb5-9173-8e883950380f',
  #                                  HoldRequestData.new)
  # @param [String] user_id the UUID of the FOLIO user
  # @param [String] item_id the UUID of the FOLIO item
  # @param [HoldRequest] request_data
  def create_item_hold(user_id, item_id, request_data)
    response = post("/patron/account/#{user_id}/item/#{item_id}/hold", json: request_data.as_json)

    check_response(response, title: 'Hold request', context: { user_id:, item_id: })

    parse_json(response)
  end

  def get_service_point(code)
    response = get_json('/service-points', params: { query: CqlQuery.new(code:).to_query })

    response.dig('servicepoints', 0)
  end

  def find_instance_by(hrid:)
    folio_graphql_client.instance(hrid:)
  end

  def circulation_rules
    get_json('/circulation-rules-storage').fetch('rulesAsText', '')
  end

  def request_policies
    @request_policies ||= get_json('/request-policy-storage/request-policies', params: { limit: 2_147_483_647 }).fetch('requestPolicies',
                                                                                                                       [])
  end

  def loan_policies
    get_json('/loan-policy-storage/loan-policies', params: { limit: 2_147_483_647 }).fetch('loanPolicies', [])
  end

  def lost_item_fees_policies
    get_json('/lost-item-fees-policies', params: { limit: 2_147_483_647 }).fetch('lostItemFeePolicies', [])
  end

  def overdue_fines_policies
    get_json('/overdue-fines-policies', params: { limit: 2_147_483_647 }).fetch('overdueFinePolicies', [])
  end

  def patron_notice_policies
    get_json('/patron-notice-policy-storage/patron-notice-policies', params: { limit: 2_147_483_647 }).fetch('patronNoticePolicies', [])
  end

  def patron_groups
    get_json('/groups', params: { limit: 2_147_483_647 }).fetch('usergroups', [])
  end

  def material_types
    get_json('/material-types', params: { limit: 2_147_483_647 }).fetch('mtypes', [])
  end

  def loan_types
    get_json('/loan-types', params: { limit: 2_147_483_647 }).fetch('loantypes', [])
  end

  def libraries
    get_json('/location-units/libraries', params: { limit: 2_147_483_647 }).fetch('loclibs', [])
  end

  def locations
    get_json('/locations', params: { limit: 2_147_483_647 }).fetch('locations', [])
  end

  def campuses
    get_json('/location-units/campuses', params: { limit: 2_147_483_647 }).fetch('loccamps', [])
  end

  def institutions
    get_json('/location-units/institutions', params: { limit: 2_147_483_647 }).fetch('locinsts', [])
  end

  def ping
    session_token.present?
  rescue Faraday::Error
    false
  end

  private

  # Find a user by barcode in FOLIO; raise an error if not found
  def find_user_by_barcode(barcode)
    get_json('/users', params: { query: CqlQuery.new(barcode:).to_query })&.dig('users', 0)
  end

  # Find a user by legacy barcode in FOLIO; raise an error if not found
  def find_user_by_legacy_barcode(barcode)
    get_json('/users', params: { query: CqlQuery.new('customFields.legacybarcode': barcode).to_query })&.dig(
      'users', 0
    )
  end

  # Find a user by university ID (externalSystemId in FOLIO); raise an error if not found
  def find_user_by_university_id(university_id)
    user = get_json('/users', params: { query: CqlQuery.new(externalSystemId: university_id).to_query })&.dig('users', 0)
    raise ActiveRecord::RecordNotFound, "User with externalSystemId '#{university_id}' not found" unless user

    user
  end

  # Find a user by sunetid (username in FOLIO); raise an error if not found
  def find_user_by_sunetid(sunetid)
    user = get_json('/users', params: { query: CqlQuery.new(username: sunetid).to_query })&.dig('users', 0)
    raise ActiveRecord::RecordNotFound, "User with username '#{sunetid}' not found" unless user

    user
  end

  # Find a user by ID in FOLIO; raise an error if not found
  def find_user_by_id(user_id)
    user = get_json("/users/#{user_id}")
    raise ActiveRecord::RecordNotFound, "User with id '#{user_id}' not found" unless user

    user
  end

  def check_response(response, title:, context:) # rubocop:disable Metrics/AbcSize
    return if response.success?

    context_string = context.map { |k, v| "#{k}: #{v}" }.join(', ')

    if response.status == 422 && Array(response.headers[Faraday::CONTENT_TYPE]).any? { |x| x.match?(/\bjson\b/) }
      raise FolioClient::Error.new("#{title} request for #{context_string} was not successful", JSON.parse(response.body))
    end

    raise "#{title} request for #{context_string} was not successful. " \
          "status: #{response.status}, #{response.body}"
  end

  def get(path, **)
    authenticated_request(path, method: :get, **)
  end

  def post(path, **)
    authenticated_request(path, method: :post, **)
  end

  def get_json(path, **)
    parse_json(get(path, **))
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
      raise response.body unless response.success?

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

  def folio_graphql_client
    @folio_graphql_client ||= FolioGraphqlClient.new
  end

  # Encryptor/decryptor for the token used in the PIN reset process
  def crypt
    @crypt ||= begin
      keygen = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base)
      key = keygen.generate_key('patron pin reset token', ActiveSupport::MessageEncryptor.key_len)
      ActiveSupport::MessageEncryptor.new(key)
    end
  end
end
