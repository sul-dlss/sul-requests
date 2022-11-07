# frozen_string_literal: true

require 'http'

class FolioClient
  DEFAULT_HEADERS = {
    accept: 'application/json, text/plain',
    content_type: 'application/json'
  }.freeze

  attr_reader :base_url

  def initialize(url: Settings.folio.url, username: nil, password: nil, tenant: 'sul')
    uri = URI.parse(url)

    @base_url = url
    @username = username
    @password = password

    if uri.user
      @username ||= uri.user
      @password ||= uri.password
      @base_url = uri.dup.tap do |u|
        u.user = nil
        u.password = nil
      end.to_s
    end

    @tenant = tenant
  end

  def get(path, **kwargs)
    authenticated_request(path, method: :get, **kwargs)
  end

  def get_json(path, **kwargs)
    parse(get(path, **kwargs))
  end

  def login(library_id, pin)
    user_response = get_json('/users', params: { query: CqlQuery.new(barcode: library_id).to_query })
    user = user_response.dig('users', 0)
    return unless user

    id = user['id']

    pid_response = get_json('/patron-pin/verify', method: :post, json: { id: id, pin: pin })

    return unless pid_response.success?

    user
  end

  def login_by_sunetid(sunetid)
    response = get_json('/users', params: { query: CqlQuery.new(username: sunetid).to_query })
    response.dig('users', 0)
  end

  def user_info(user_id)
    get_json("/users/#{CGI.escape(user_id)}")
  end

  def patron_info(patron_key, loans: true, charges: true, holds: true)
    get_json("/patron/account/#{CGI.escape(patron_key)}", params: {
      includeLoans: loans,
      includeCharges: charges,
      includeHolds: holds
    })
  end

  def batch_request(json)
    get_json('/request-storage-batch/requests', method: :post, json: json)
  end

  def ping
    session_token.present?
  rescue HTTP::Error
    false
  end

  private

  def parse(response)
    return nil if response.body.empty?

    JSON.parse(response.body)
  end

  def session_token
    @session_token ||= begin
      response = request('/authn/login', json: { username: @username, password: @password }, method: :post)
      response['x-okapi-token']
    end
  end

  def authenticated_request(path, headers: {}, **other)
    request(path, headers: headers.merge('x-okapi-token': session_token), **other)
  end

  def request(path, headers: {}, method: :get, **other)
    HTTP
      .use(instrumentation: { instrumenter: ActiveSupport::Notifications.instrumenter, namespace: 'folio' })
      .headers(default_headers.merge(headers))
      .request(method, base_url + path, **other)
  end

  def default_headers
    DEFAULT_HEADERS.merge({ 'X-Okapi-Tenant': @tenant, 'User-Agent': 'FolioApiClient' })
  end
end
