###
#  Request class for making requests
#  to place a hold or recall on an item
###
class HoldRecall < Request
  include TokenEncryptable

  validates :needed_date, presence: true

  def requestable_with_library_id?
    true
  end

  def requires_needed_date?
    true
  end
end
