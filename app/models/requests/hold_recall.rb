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
    ilb_eligible? ? submit_ilb_request_job : send_to_ils_later!
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

  private

  def ilb_eligible?
    case Settings.features.hold_recall_via
    when 'illiad'
      user.sunetid && user.patron.ilb_eligible?
    when 'reshare'
      user.patron.ilb_eligible?
    end
  end

  def submit_ilb_request_job
    case Settings.features.hold_recall_via
    when 'illiad'
      SubmitIlliadRequestJob.perform_later(id)
    when 'reshare'
      SubmitReshareRequestJob.perform_later(id)
    else
      super
    end
  end
end
