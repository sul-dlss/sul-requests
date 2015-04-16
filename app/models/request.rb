###
#  Main Request class.  All other requests use
#  STI and sub-class this main request class.
###
class Request < ActiveRecord::Base
  validates :item_id, :origin, :origin_location, presence: true
  def new_request?
    status.present?
  end

  def scannable?
    origin == 'SAL3' && origin_location == 'STACKS'
  end
end
