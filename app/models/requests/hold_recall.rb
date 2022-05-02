# frozen_string_literal: true

###
#  Request class for making requests
#  to place a hold or recall on an item
###
class HoldRecall < Request
  include TokenEncryptable

  validates :needed_date, presence: true

  def submit!
    return super unless request_via_borrow_direct?

    SubmitBorrowDirectRequestJob.perform_later(id)
  end

  # Allow requests with Library ID
  def requestable_with_library_id?
    true
  end

  def requires_needed_date?
    true
  end

  def item_commentable?
    false
  end

  def request_via_borrow_direct?
    Settings.features.hold_recall_via_borrow_direct
  end
end
