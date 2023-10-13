# frozen_string_literal: true

# Mixin for requests that can be sent to ILLiad
module Illiadable
  def notify_ilb!
    IlbMailer.ilb_notification(self).deliver_later
  end

  def illiad_error?
    return false if illiad_response_data.blank?

    illiad_response_data['Message'].present?
  end

  def illiad_request_params
    default_illiad_request_params.merge(special_illiad_request_params).compact
  end

  # Override to customize params sent for a specific request type
  def special_illiad_request_params
    {}
  end

  private

  # These are always sent to ILLiad, regardless of request type
  # For more details, see the parameter mapping spreadsheet:
  # https://docs.google.com/spreadsheets/d/1bvMuOL4xDjAlXl-QjpsTWHf8Lc3icB7O3ED3FDmKvTQ/edit?usp=sharing
  # And ILLiad docs for the API:
  # https://support.atlas-sys.com/hc/en-us/articles/360011809394-The-ILLiad-Web-Platform-API#h_01FCP7ZPFFT22TX87CGYP70V0J
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def default_illiad_request_params
    {
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
end
