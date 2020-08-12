# frozen_string_literal: true

###
#  Class to handle creation of ILLiad OpenURL request
###
class IlliadRequest
  def initialize(scan)
    @scan = scan
  end

  def illiad_transaction_request
    illiad_user.merge(illiad_route.merge(illiad_bib.merge(illiad_item))).to_json
  end

  def request!
    faraday_conn_w_req_headers.post('ILLiadWebPlatform/Transaction/', illiad_transaction_request)
  end

  private

  def illiad_user
    { 'Username': @scan.user.webauth }
  end

  def illiad_route
    {
      'ProcessType': 'Borrowing',
      'RequestType': 'Article',
      'SpecIns': 'Scan and Deliver Request'
    }
  end

  def illiad_bib
    {
      'PhotoJournalTitle': @scan.searchworks_item.title,
      'PhotoArticleAuthor': @scan.authors,
      'PhotoArticleTitle': @scan.data[:section_title],
      'PhotoJournalInclusivePages': @scan.data[:page_range],
      'Loaction': @scan.origin,
      'ReferenceNumber': @scan.origin_location
    }
  end

  def illiad_item
    {
      'CallNumber': first_holding.try(:callnumber),
      'ILLNumber': first_holding.try(:barcode),
      'ItemNumber': first_holding.try(:barcode)
    }
  end

  def illiad_url
    Settings.sul_illiad
  end

  def first_holding
    @scan.holdings.first
  end

  def faraday_conn_w_req_headers
    Faraday.new(url: illiad_url) do |req|
      req.headers['ApiKey'] = Settings.illiad_api_key
      req.headers['Accept'] = 'application/json; version=1'
      req.headers['Content-type'] = 'application/json'
      req.adapter Faraday.default_adapter
    end
  end
end
