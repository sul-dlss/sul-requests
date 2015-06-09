require 'csv'

# API for checking the proxy status of a library id
class ProxyAccess
  include ActiveModel::Model

  attr_accessor :libid

  def sponsor?
    sponsors.any?
  end

  def proxy?
    proxies.any?
  end

  private

  def sponsors
    where(status: 'SPONSOR')
  end

  def proxies
    where(status: 'PROXY')
  end

  def where(hash = {})
    table.select do |row|
      hash.all? do |k, v|
        row[k] == v
      end
    end
  end

  def table
    @table ||= CSV.parse(response.body, headers: [:name, :status], col_sep: '|')
  end

  def response
    @response ||= begin
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
    Settings.sul_proxy_api_url % { libid: ERB::Util.url_encode(libid) }
  end
end
