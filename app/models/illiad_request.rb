# frozen_string_literal: true

###
#  Class to handle creation of ILLiad request
###
class IlliadRequest
  include IlliadClient

  def initialize(current_user, scan)
    @current_user = current_user
    @scan = scan
  end

  # rubocop:disable Metrics/MethodLength
  def illiad_transaction_request
    {
      'ProcessType': 'Borrowing',
      'RequestType': 'Article',
      'SpecIns': 'Scan and Deliver Request',
      'PhotoJournalTitle': scan_title,
      'PhotoArticleAuthor': scan_authors,
      'Loaction': scan_origin,
      'ReferenceNumber': scan_origin_location,
      'PhotoArticleTitle': scan_data[:section_title],
      'PhotoJournalInclusivePages': scan_data[:page_range],
      'CallNumber': call_number,
      'ILLNumber': ill_number,
      'ItemNumber': item_number,
      'Username': illiad_user
    }
  end
  # rubocop:enable Metrics/MethodLength

  def response
    connection_with_headers.post(
      'ILLiadWebPlatform/Transaction/', illiad_transaction_request
    )
  rescue Faraday::ConnectionFailed => e
    Rails.logger.warn("HTTP POST for #{Settings.sul_illiad} failed with: #{e}")
    NullResponse.new
  end

  private

  def illiad_user
    @current_user.webauth
  end

  def scan_authors
    @scan.authors
  end

  def scan_data
    @scan.data
  end

  def scan_title
    @scan.searchworks_item.title
  end

  def scan_origin_location
    @scan.origin_location
  end

  def scan_origin
    @scan.origin
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
end
