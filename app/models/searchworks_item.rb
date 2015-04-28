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
    @response ||= Faraday.get(url)
  end

  def json
    @json ||= JSON.parse(response.body) || {}
  end
end
