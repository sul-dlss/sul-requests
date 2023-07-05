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
end
