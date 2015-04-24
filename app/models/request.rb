###
#  Main Request class.  All other requests use
#  STI and sub-class this main request class.
###
class Request < ActiveRecord::Base
  validates :item_id, :origin, :origin_location, presence: true

  serialize :data, Hash

  belongs_to :user, autosave: true
  accepts_nested_attributes_for :user

  def new_request?
    status.present?
  end

  def scannable?
    origin == 'SAL3' && origin_location == 'STACKS'
  end

  def library_location
    @library_location ||= LibraryLocation.new(self)
  end

  def searchworks_item
    @searchworks_item ||= SearchworksItem.new(item_id)
  end

  def commentable?
    false
  end

  # This method gets called when saving the user assocation
  # and allows us to make sure we assign the user object if
  # there already is one associated with that email address
  def autosave_associated_records_for_user
    return unless user
    if (existing_user = find_existing_user)
      self.user = existing_user
    else
      user.save!
      self.user = user
    end
  end

  def find_existing_user
    return unless user
    if user.webauth_user?
      User.find_by_webauth(user.webauth)
    elsif user.non_webauth_user?
      User.find_by_email(user.email)
    end
  end
end
