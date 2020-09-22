# frozen_string_literal: true

###
#  Class to handle creation of ILLiad OpenURL request
###
class IlliadRequest
  def initialize(scan)
    @scan = scan
  end

  # rubocop:disable Metrics/MethodLength
  def illiad_transaction_request
    {
      'ProcessType': 'Borrowing',
      'RequestType': 'Article',
      'SpecIns': 'Scan and Deliver Request',
      'PhotoJournalTitle': scan_title,
      'PhotoArticleAuthor': @scan.authors,
      'Location': @scan.origin,
      'ReferenceNumber': @scan.origin_location,
      'PhotoArticleTitle': @scan.data[:section_title],
      'PhotoJournalInclusivePages': @scan.data[:page_range],
      'CallNumber': call_number,
      'ILLNumber': ill_number,
      'ItemNumber': item_number,
      'Username': @scan.user.webauth
    }.to_json
  end
  # rubocop:enable Metrics/MethodLength

  def request!
    faraday_conn_w_req_headers.post('ILLiadWebPlatform/Transaction/', illiad_transaction_request)
  end

  private

  def scan_title
    @scan.searchworks_item.title
  end

  def ill_number
    first_holding.try(:barcode)
  end

  def item_number
    first_holding.try(:barcode)
  end

  def call_number
    first_holding.try(:callnumber)
  end

  def first_holding
    @scan.holdings.first
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
