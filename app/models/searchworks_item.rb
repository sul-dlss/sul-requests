###
#  Class to connect to the searchworks availability API
#  The API URI is configured using rails_config: Settings.searchworks_api
###
class SearchworksItem
  attr_reader :request
  def initialize(request)
    @request = request
  end

  def title
    json['title'] || ''
  end

  def format
    json['format'] || []
  end

  def holdings
    return [] unless json['holdings'].present?
    @holdings ||= JSON.parse(json['holdings'].to_json, object_class: OpenStruct)
  end

  def requested_holdings
    @requested_holdings ||= RequestedHoldings.new(self)
  end

  private

  def base_uri
    Settings.searchworks_api
  end

  def url
    [base_uri, 'view', request.item_id, 'availability'].join('/')
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

  ###
  #  ReqestedHoldings winnows down the entire
  #  holdings to just what was requested by the user
  ###
  class RequestedHoldings
    def initialize(searchworks_item)
      @searchworks_item = searchworks_item
    end

    def where(barcodes: [])
      fail ArgumentError unless barcodes.present?
      barcodes = Array(barcodes)
      all.select do |item|
        barcodes.include?(item.barcode)
      end
    end

    def all
      return [] unless location.present?
      location.items.map do |item|
        item.request_status = @searchworks_item.request.item_status(item.barcode)
        item
      end
    end

    def barcoded_holdings
      @barcoded_holdings ||= all.select do |item|
        item.barcode.match(barcode_pattern)
      end
    end

    def mhld
      return [] unless location.present? && location.mhld.present?
      location.mhld
    end

    def library_instructions
      library.library_instructions if library && library.library_instructions.present?
    end

    private

    def barcode_pattern
      /^36105/
    end

    def library
      return unless @searchworks_item.holdings.present?
      @searchworks_item.holdings.find do |library|
        library.code == @searchworks_item.request.origin
      end
    end

    def location
      return unless library.present?
      library.locations.find do |location|
        location.code == @searchworks_item.request.origin_location
      end
    end
  end
end
