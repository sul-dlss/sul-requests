# frozen_string_literal: true

###
#  Request class for making requests
#  to place a hold or recall on an item
###
class HoldRecall < Request
  include TokenEncryptable

  validates :needed_date, presence: true

  def submit!
    if Settings.features.hold_recall_via_reshare
      SubmitReshareRequestJob.perform_later(id)
    else
      super
    end
  end

  def requires_needed_date?
    true
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def illiad_request_params
    {
      RequestType: 'Loan',
      SpecIns: 'Hold/Recall Request',
      LoanTitle: bib_data.title,
      LoanAuthor: bib_data.author,
      ISSN: bib_data.isbn,
      LoanPublisher: bib_data.publisher,
      LoanPlace: bib_data.pub_place,
      LoanDate: bib_data.pub_date,
      LoanEdition: bib_data.edition,
      ESPNumber: bib_data.oclcn,
      CitedIn: bib_data.view_url,
      PhotoJournalVolume: holdings.first.try(:volume),
      NotWantedAfter: needed_date.strftime('%Y-%m-%d'),
      ItemInfo4: destination_library_code
    }
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
