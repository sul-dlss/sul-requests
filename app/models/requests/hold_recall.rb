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

  # TODO: COVID-19 Disabling for now while we re-open so that it falls back to the default behavior
  # We can uncomment if we want HoldRecalls to be requestable by non-SUNet users in the future.
  # def requestable_with_library_id?
  #   true
  # end

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
