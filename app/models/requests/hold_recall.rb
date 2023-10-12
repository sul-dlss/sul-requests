# frozen_string_literal: true

###
#  Request class for making requests
#  to place a hold or recall on an item
###
class HoldRecall < Request
  include TokenEncryptable
  include Illiadable

  validates :needed_date, presence: true

  def submit!
    case Settings.features.hold_recall_via
    when 'illiad'
      SubmitIlliadRequestJob.perform_later(id)
    when 'reshare'
      SubmitReshareRequestJob.perform_later(id)
    else
      super
    end
  end

  def requires_needed_date?
    true
  end

  def special_illiad_request_params
    {
      RequestType: 'Loan',
      SpecIns: 'Hold/Recall Request',
      LoanTitle: bib_data.title,
      LoanAuthor: bib_data.author,
      NotWantedAfter: needed_date.strftime('%Y-%m-%d'),
      ItemInfo4: destination_library_code
    }
  end
end
