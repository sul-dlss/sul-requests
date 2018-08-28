# frozen_string_literal: true

###
#  Class to handle creation of ILLiad client
###
module IlliadClient
  def connection_with_headers
    Faraday.new(url: Settings.sul_illiad) do |req|
      req.adapter Faraday.default_adapter
      req.headers = {
        'ApiKey': Settings.illiad_api_key,
        'Accept': 'application/json; version=1',
        'Content-type': 'application/json'
      }
    end
  end
end
