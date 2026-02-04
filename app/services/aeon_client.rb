# frozen_string_literal: true

# Calls Aeon REST endpoints
class AeonClient
  DEFAULT_HEADERS = {
    accept: 'application/json',
    'odata.metadata': 'minimal',
    'odata.streaming': true
  }.freeze

  def requests(**args)
    get_json("/Users/#{current_user.email}/requests", params: { activeOnly: true })
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

  def get(path, **)
    authenticated_request(path, method: :get, **)
  end

  def authenticated_request(path, method:, params: nil, headers: DEFAULT_HEADERS, json: nil)
    request(path, method:, params:, headers: headers.merge('X-AEON-API-KEY': Settings.aeon.token), json:)
  end
end