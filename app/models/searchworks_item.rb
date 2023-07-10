# frozen_string_literal: true

###
#  Class to connect to the searchworks availability API
#  The API URI is configured using rails_config: Settings.searchworks_api
###
class SearchworksItem
  attr_reader :request, :live_lookup, :json, :catkey

  def self.fetch(request, live_lookup = true)
    response = begin
      Faraday.get(url_for(request.item_id, live: live_lookup))
    rescue Faraday::ConnectionFailed
      NullResponse.new
    end

    json = begin
      JSON.parse(response.body) if response.success?
    rescue JSON::ParserError
      nil
    end

    new(json || {}, request.item_id)
  end

  def self.url_for(catkey, **kwargs)
    base_url = [Settings.searchworks_api, 'view', catkey, 'availability'].join('/')
    params = kwargs.reject { |k, v| k == :live && v == true }.to_param.presence
    [base_url, params].compact.join('?')
  end

  def initialize(json, catkey)
    @json = json
    @catkey = catkey
  end

  def title
    json['title'] || ''
  end

  def author
    json['author'] || ''
  end

  def pub_date
    json['pub_date'] || ''
  end

  def format
    json['format'] || []
  end

  def isbn
    json['isbn'] || []
  end

  def finding_aid
    json['finding_aid'] || ''
  end

  def request_holdings(request)
    Searchworks::Holdings.new(request, holdings)
  end

  def holdings
    @holdings ||= (json['holdings'] || []).map { |holding| Searchworks::Holding.new(holding) }
  end

  def finding_aid?
    !!json['finding_aid']
  end

  def view_url
    [base_uri, 'view', catkey].join('/')
  end

  private

  def base_uri
    Settings.searchworks_api
  end
end
