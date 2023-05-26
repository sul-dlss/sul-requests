# frozen_string_literal: true

###
#  Class to connect to the searchworks availability API
#  The API URI is configured using rails_config: Settings.searchworks_api
###
class SearchworksItem
  attr_reader :request, :live_lookup

  def initialize(request, live_lookup = true)
    @request = request
    @live_lookup = live_lookup
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

  def holdings
    return [] unless json['holdings'].present?

    @holdings ||= JSON.parse(json['holdings'].to_json, object_class: OpenStruct)
  end

  def finding_aid?
    !!json['finding_aid']
  end

  def view_url
    [base_uri, 'view', request.item_id].join('/')
  end

  private

  def base_uri
    Settings.searchworks_api
  end

  def url
    full_url = [view_url, 'availability'].join('/')
    full_url << '?live=false' unless live_lookup
    full_url
  end

  def response
    @response ||= begin
      Faraday.get(url)
    rescue Faraday::ConnectionFailed
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
end
