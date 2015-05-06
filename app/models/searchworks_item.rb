###
#  Class to connect to the searchworks availability API
#  The API URI is configured using rails_config: Settings.searchworks_api
###
class SearchworksItem
  def initialize(item_id)
    @item_id = item_id
  end

  def title
    json['title'] || ''
  end

  def holdings
    return [] unless json['holdings'].present?
    @holdings ||= JSON.parse(json['holdings'].to_json, object_class: OpenStruct)
  end

  private

  def base_uri
    Settings.searchworks_api
  end

  def url
    [base_uri, 'view', @item_id, 'availability'].join('/')
  end

  def response
    @response ||= begin
      Faraday.get(url)
    rescue Faraday::Error::ConnectionFailed
      NullResponse.new
    end
  end

  def json
    return {} unless response.success?
    @json ||= begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      {}
    end
  end

  # Response class to return when the API connection fails
  class NullResponse
    def success?
      false
    end
  end
end
