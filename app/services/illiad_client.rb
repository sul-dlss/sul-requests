# frozen_string_literal: true

# Client for the Illiad API
class IlliadClient
  # Accepts a Faraday::Response or plain message to report on Illiad API errors
  class ApiError < StandardError
    attr_reader :response

    def initialize(response_or_message = nil)
      if response_or_message.is_a?(Faraday::Response)
        @response = response_or_message
        super("Illiad API #{response.env.method.to_s.upcase} #{response.env.url.path} failed: #{response.status}")
      else
        super
      end
    end

    def to_honeybadger_context
      return {} unless response

      env = response.env
      {
        status: response.status,
        method: env.method.to_s.upcase,
        url: env.url.to_s,
        request_body: env.request_body,
        response_body: response.body
      }
    end
  end

  def initialize(url: Settings.sul_illiad, api_key: Settings.illiad_api_key)
    @base_url = url
    @api_key = api_key
  end

  def create(params)
    response = connection.post('ILLiadWebPlatform/Transaction/', params, content_type: 'application/json')

    handle_response(response, as_class: Illiad::Request)
  end

  def user_transactions(user_id)
    response = connection.get("ILLiadWebPlatform/Transaction/UserRequests/#{user_id}")

    handle_response(response, as_class: Illiad::Request, not_found: [])
  end

  def create_transaction_note(transaction_number:, note:)
    connection.post("ILLiadWebPlatform/Transaction/#{transaction_number}/Note", { Note: note, NoteType: 'Staff' },
                    content_type: 'application/json')

    handle_response(response)
  end

  def update_request_route(transaction_number:, status:)
    response = connection.put("ILLiadWebPlatform/transaction/#{transaction_number}/route", { Status: status },
                              content_type: 'application/json')

    handle_response(response, as_class: Illiad::Request)
  end

  private

  def connection
    Faraday.new(url: @base_url) do |req|
      req.request :json
      req.response :json

      default_headers.each do |k, v|
        req.headers[k] = v
      end

      req.adapter Faraday.default_adapter
    end
  end

  def default_headers
    { ApiKey: @api_key, Accept: 'application/json; version=1' }
  end

  def handle_response(faraday_response, as_class: nil, not_found: nil) # rubocop:disable Metrics/MethodLength
    if faraday_response.success?
      body = faraday_response.body
      return yield body unless as_class

      if body.is_a?(Array)
        Array.wrap(body).map { |data| as_class.from_dynamic(data) }
      else
        as_class.from_dynamic(body)
      end
    elsif faraday_response.status == 404
      not_found
    else
      raise ApiError, faraday_response
    end
  end
end
