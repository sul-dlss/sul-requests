# frozen_string_literal: true

##
# API for retrieving the username and email from a library id
class SymphonyUserNameRequest
  include ActiveModel::Model

  attr_accessor :libid

  def name
    match[:name].try(:strip)
  end

  def email
    match[:email]
  end

  private

  def match
    @match ||= response.body.match(/\A(?<name>[^(]+)\((?<email>[^)]+)\)\Z/) || {}
  end

  def response
    @response ||= begin
      return empty_response('No proxy-api url configured') unless request_url.present?

      response = Faraday.get(request_url)

      return empty_response(response.body) unless response.success?

      response
    rescue Faraday::Error::ConnectionFailed => e
      empty_response(e)
    end
  end

  def empty_response(error = nil)
    Rails.logger.warn("HTTP GET for #{request_url} failed with: #{error}")
    NullResponse.new
  end

  def request_url
    Settings.sul_user_name_api_url % { libid: ERB::Util.url_encode(libid) }
  end
end
