###
#  Class to connect to the searchworks API at http://searchworks.stanford.edu/view/#{ckey}.mobile?covers=false
#  The API URI is configured using rails_config: Settings.searchworks_api
###
class SearchworksItem
  def initialize(item_id)
    @item_id = item_id
  end

  def title
    item_xml['title'] || ''
  end

  private

  def item_xml
    response_xml['LBItem'] || {}
  end

  def response_xml
    xml_hash['response'] || {}
  end

  def uri
    Settings.searchworks_api
  end

  def url
    "#{uri}/view/#{@item_id}.mobile?covers=false"
  end

  def response
    @response ||= Faraday.get(url)
  end

  def xml
    response.body
  end

  def xml_hash
    @xml_hash ||= Hash.from_xml(xml)
  end
end
