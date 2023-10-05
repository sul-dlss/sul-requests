# frozen_string_literal: true

###
#  Class to handle creation of ILLiad OpenURL request
###
class IlliadRequest
  def initialize(request)
    @request = request
  end

  def request!
    faraday_conn_w_req_headers.post(
      'ILLiadWebPlatform/Transaction/',
      default_params.merge(@request.illiad_request_params).compact.to_json
    )
  end

  private

  def default_params
    {
      Username: @request.user.sunetid,
      ProcessType: 'Borrowing'
    }
  end

  def faraday_conn_w_req_headers
    Faraday.new(url: Settings.sul_illiad) do |req|
      req.headers['ApiKey'] = Settings.illiad_api_key
      req.headers['Accept'] = 'application/json; version=1'
      req.headers['Content-type'] = 'application/json'
      req.adapter Faraday.default_adapter
    end
  end
end
