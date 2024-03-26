# frozen_string_literal: true

# Builds the parameters to send to ILLiad
class IlliadRequestParameters
  def self.build(request)
    new(request).build
  end

  def initialize(request)
    @request = request
  end

  def build
    default_illiad_request_params.merge(special_illiad_request_params).compact
  end

  private

  attr_reader :request

  delegate :user, :bib_data, :holdings, :origin, :origin_location, :section_title,
           :page_range, :needed_date, :destination_library_code, to: :request

  # These are always sent to ILLiad, regardless of request type
  # For more details, see the parameter mapping spreadsheet:
  # https://docs.google.com/spreadsheets/d/1bvMuOL4xDjAlXl-QjpsTWHf8Lc3icB7O3ED3FDmKvTQ/edit?usp=sharing
  # And ILLiad docs for the API:
  # https://support.atlas-sys.com/hc/en-us/articles/360011809394-The-ILLiad-Web-Platform-API#h_01FCP7ZPFFT22TX87CGYP70V0J
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def default_illiad_request_params
    {
      RequestType: request_type,
      SpecIns: spec_ins,
      ProcessType: 'Borrowing',
      AcceptAlternateEdition: false,
      Username: user.sunetid,
      UserInfo1: user.patron.blocked? ? 'Blocked' : nil,
      ISSN: bib_data.isbn,
      LoanPublisher: bib_data.publisher,
      LoanPlace: bib_data.pub_place,
      LoanDate: bib_data.pub_date,
      LoanEdition: bib_data.edition,
      ESPNumber: bib_data.oclcn,
      CitedIn: bib_data.view_url,
      CallNumber: holdings.first.try(:callnumber),
      ILLNumber: holdings.first.try(:barcode),
      ItemNumber: holdings.first.try(:barcode),
      PhotoJournalVolume: holdings.first.try(:enumeration)
    }
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def special_illiad_request_params
    case request
    when HoldRecall
      hold_recall_request_params
    when Scan
      scan_request_parameters
    end
  end

  def request_type
    case request
    when HoldRecall
      'Loan'
    when Scan
      'Article'
    end
  end

  def spec_ins
    case request
    when HoldRecall
      'Hold/Recall Request'
    when Scan
      'Scan and Deliver Request'
    end
  end

  def scan_request_parameters
    {
      PhotoJournalTitle: bib_data.title,
      PhotoArticleAuthor: bib_data.author,
      Location: origin,
      ReferenceNumber: origin_location,
      PhotoArticleTitle: section_title,
      PhotoJournalInclusivePages: page_range
    }
  end

  def hold_recall_request_params
    {
      LoanTitle: bib_data.title,
      LoanAuthor: bib_data.author,
      NotWantedAfter: needed_date.strftime('%Y-%m-%d'),
      ItemInfo4: destination_library_code
    }
  end
end
