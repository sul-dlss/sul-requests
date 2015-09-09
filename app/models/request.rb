###
#  Main Request class.  All other requests use
#  STI and sub-class this main request class.
###
class Request < ActiveRecord::Base
  include Commentable
  include Holdings
  include Requestable
  include DefaultRequestOptions
  include RequestValidations

  attr_accessor :requested_barcode
  alias_method :barcode=, :requested_barcode=

  delegate :hold_recallable?, :mediateable?, :pageable?, :scannable?, to: :library_location

  # Serialzed data hash
  store :data, accessors: [
    :ad_hoc_items, :authors, :request_status_data, :item_comment, :page_range,
    :proxy, :request_comment, :section_title, :symphony_response_data
  ], coder: JSON
  serialize :barcodes, Array

  belongs_to :user, autosave: true
  accepts_nested_attributes_for :user

  before_create do
    self.item_title ||= searchworks_item.title
  end

  def library_location
    @library_location ||= LibraryLocation.new(self)
  end

  def active_messages
    library_location.active_messages.for_type(Message.notification_type(self))
  end

  def searchworks_item
    @searchworks_item ||= SearchworksItem.new(self)
  end

  def send_confirmation!
    ConfirmationMailer.request_confirmation(self).deliver_later if notification_email_address.present?
  end

  def delegate_request!
    case
    when mediateable? then self.becomes!(MediatedPage)
    when hold_recallable? then self.becomes!(HoldRecall)
    else self.becomes!(Page)
    end
  end

  def stored_or_fetched_item_title
    if persisted?
      item_title
    else
      searchworks_item.title
    end
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
    elsif user.library_id_user?
      User.find_by_library_id(user.library_id)
    elsif user.non_webauth_user?
      find_existing_email_user
    end
  end

  def find_existing_email_user
    User.find_by_email(user.email).tap do |u|
      next unless u
      u.update_attributes(name: user.name)
    end
  end

  def data_to_email_s
    %w(comments page_range section_title authors).map do |field|
      if (data_field = data[field]).present?
        "#{self.class.human_attribute_name(field)}:\n  #{data_field}"
      end
    end.compact.join("\n")
  end

  def proxy?
    proxy == true
  end

  def notification_email_address
    if proxy? && user.proxy_access.email_address.present?
      user.proxy_access.email_address
    elsif user.email_address.present?
      user.email_address
    end
  end

  def submit!
    send_to_symphony!
  end

  def send_to_symphony!(options = {})
    SubmitSymphonyRequestJob.perform_now(self, options)
  end

  def appears_in_myaccount?
    user.webauth_user?
  end

  class << self
    # The mediateable_oirgins will make multiple (efficient) database requests
    # in order to return the array of locations that are both configured as mediateable and have existing requests.
    # Another alternative would be to use (origin_admin_groups & uniq.pluck(:origin)).present? but that will result
    # in a SELECT DISTNICT which could get un-performant with a large table of requests.
    def mediateable_origins
      Settings.origin_admin_groups.to_hash.keys.map(&:to_s).select do |library_or_location|
        MediatedPage.exists?(origin: library_or_location) || MediatedPage.exists?(origin_location: library_or_location)
      end
    end
  end

  def item_status(id)
    ItemStatus.new(self, id)
  end

  def symphony_response
    @symphony_response ||= SymphonyResponse.new(symphony_response_data || {})
  end

  def symphony_response_will_change!
    @symphony_response = nil
  end
end
