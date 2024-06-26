# frozen_string_literal: true

###
#  Class to handle creation of ILLiad OpenURL request
###
class IlliadRequest
  def initialize(illiad_request_params)
    @illiad_request_params = illiad_request_params
  end

  def request!
    faraday_conn_w_req_headers.post('ILLiadWebPlatform/Transaction/', @illiad_request_params.to_json)
  end

  private

  def faraday_conn_w_req_headers
    Faraday.new(url: Settings.sul_illiad) do |req|
      req.headers['ApiKey'] = Settings.illiad_api_key
      req.headers['Accept'] = 'application/json; version=1'
      req.headers['Content-type'] = 'application/json'
      req.adapter Faraday.default_adapter
    end
  end
end
