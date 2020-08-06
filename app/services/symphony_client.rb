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
    Settings.symws.url
  end

  def default_headers
    DEFAULT_HEADERS.merge(Settings.symws.headers || {})
  end
end
