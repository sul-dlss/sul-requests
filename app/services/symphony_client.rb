# frozen_string_literal: true

# HTTP client wrapper for making requests to Symws
class SymphonyClient
  DEFAULT_HEADERS = {
    accept: 'application/json',
    content_type: 'application/json'
  }.freeze

  # ping the symphony endpoint to make sure we can establish a connection
  def ping
    session_token.present?
  rescue HTTP::Error
    false
  end

  def login(library_id, pin)
    response = authenticated_request('/user/patron/authenticate', method: :post, json: {
                                       barcode: library_id,
                                       password: pin
                                     })

    JSON.parse(response.body)
  end

  def login_by_sunetid(sunetid)
    response = authenticated_request('/user/patron/search', params: {
                                       q: "webAuthID:#{sunetid}",
                                       includeFields: '*'
                                     })

    JSON.parse(response.body)['result'].first
  end

  # get a session token by authenticating to symws
  def session_token
    @session_token ||= begin
      response = request('/user/staff/login', json: Settings.symws.login_params, method: :post)

      JSON.parse(response.body)['sessionToken']
    rescue JSON::ParserError
      Honeybadger.notify('Unable to connect to Symphony Web Services.')
      nil
    end
  end

  def catalog_info(key)
    headers = if Settings.symws.headers
                {}
              else
                guest_headers
              end

    response = request("/catalog/item/barcode/#{ERB::Util.url_encode(key)}", params: {
                         includeFields: 'currentLocation'
                       }, headers: headers)

    JSON.parse(response.body)
  rescue JSON::ParserError, HTTP::Error
    nil
  end

  # rubocop:disable Metrics/ParameterLists
  def place_hold(fill_by_date:, key: 'GREEN', recall_status: 'STANDARD', item: {}, patron_barcode:, for_group: false, comment:)
    response = authenticated_request('/circulation/holdRecord/placeHold', method: :post, json: {
      comment: comment.truncate(50, omission: ''),
      fillByDate: (fill_by_date || DateTime.now + 3.years).strftime('%Y-%m-%d'),
      holdRange: 'SYSTEM',
      patronBarcode: patron_barcode,
      pickupLibrary: {
        key: key,
        resource: '/policy/library'
      },
      recallStatus: recall_status
    }.merge(item), headers: { 'SD-Prompt-Return': "GROUP_PROMPT/#{for_group}", 'SD-Working-LibraryID': 'SUL' })
    JSON.parse(response.body)
  rescue JSON::ParserError, HTTP::Error
    nil
  end
  # rubocop:enable Metrics/ParameterLists

  # rubocop:disable Metrics/MethodLength
  def patron_info(patron_key)
    response = authenticated_request("/user/patron/key/#{patron_key}", params: {
                                       includeFields: [
                                         '*',
                                         'address1',
                                         'profile{chargeLimit}',
                                         'customInformation{*}',
                                         'groupSettings{*,group{memberList{*}}}'
                                       ].join(',')
                                     })

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  def response_prompt(response)
    return if response.status.ok?

    JSON.parse(response.body).dig('dataMap', 'promptType')
  rescue JSON::ParserError
    nil
  end

  def authenticated_request(path, headers: {}, **other)
    request(path, headers: headers.merge('x-sirs-sessionToken': session_token), **other)
  end

  def request(path, headers: {}, method: :get, **other)
    HTTP
      .use(instrumentation: { instrumenter: ActiveSupport::Notifications.instrumenter, namespace: 'symphony' })
      .headers(default_headers.merge(headers))
      .request(method, base_url + path, **other)
  end

  def base_url
    Settings.symws.url || Settings.symphony_web_services&.base_url
  end

  def default_headers
    DEFAULT_HEADERS.merge(Settings.symws.headers || {})
  end

  def guest_headers
    {
      'x-sirs-clientID': 'DS_CLIENT',
      'sd-originating-app-id': 'requests',
      'SD-Preferred-Role': 'GUEST'
    }
  end
end
