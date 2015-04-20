###
#  Main Request class.  All other requests use
#  STI and sub-class this main request class.
###
class Request < ActiveRecord::Base
  validates :item_id, :origin, :origin_location, presence: true

  belongs_to :user, autosave: true
  accepts_nested_attributes_for :user

  def new_request?
    status.present?
  end

  def scannable?
    origin == 'SAL3' && origin_location == 'STACKS'
  end

  # This method gets called when saving the user assocation
  # and allows us to make sure we assign the user object if
  # there already is one associated with that email address
  def autosave_associated_records_for_user
    return unless user
    if (new_user = User.find_by_email(user.email))
      self.user = new_user
    else
      user.save!
    end
  end
end
