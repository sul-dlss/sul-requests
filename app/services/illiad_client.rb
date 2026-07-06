# frozen_string_literal: true

# Client for the Illiad API
class IlliadClient
  def initialize(url: Settings.sul_illiad, api_key: Settings.illiad_api_key)
    @base_url = url
    @api_key = api_key
  end

  def create(params)
    response = connection.post('ILLiadWebPlatform/Transaction/', params.to_json, content_type: 'application/json')

    JSON.parse(response.body) if response.success?
  end

  def user_transactions(user_id)
    response = connection.get("ILLiadWebPlatform/Transaction/UserRequests/#{user_id}")

    JSON.parse(response.body) if response.success?
  rescue StandardError => e
    Honeybadger.notify(e, error_message: "Unable to retrieve ILLIAD transactions with #{e}")
    []
  end

  private

  def connection
    Faraday.new(url: Settings.sul_illiad) do |req|
      req.headers['ApiKey'] = Settings.illiad_api_key
      req.headers['Accept'] = 'application/json; version=1'
      req.adapter Faraday.default_adapter
    end
  end
end
