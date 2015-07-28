###
#  Main Request class.  All other requests use
#  STI and sub-class this main request class.
###
class Request < ActiveRecord::Base
  include Commentable
  include Holdings
  include Requestable

  attr_accessor :requested_barcode
  alias_method :barcode=, :requested_barcode=

  delegate :hold_recallable?, :mediateable?, :pageable?, :scannable?, to: :library_location

  validates :item_id, :origin, :origin_location, presence: true
  validate :requested_holdings_exist

  # Serialzed data hash
  store :data, accessors: [
    :ad_hoc_items, :authors, :request_status_data, :item_comment, :page_range, :proxy, :request_comment, :section_title
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
    elsif user.non_webauth_user?
      User.find_by_email(user.email)
    end
  end

  def item_limit
    nil
  end

  def data_to_email_s
    %w(comments page_range section_title authors).map do |field|
      if (data_field = data[field]).present?
        "#{self.class.human_attribute_name(field)}:\n  #{data_field}"
      end
    end.compact.join("\n")
  end

  def requires_needed_date?
    false
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

  class << self
    # The mediateable_oirgins will make multiple (efficient) database requests
    # in order to return the array of locations that are both configured as mediateable and have existing requests.
    # Another alternative would be to use (origin_admin_groups & uniq.pluck(:origin)).present? but that will result
    # in a SELECT DISTNICT which could get un-performant with a large table of requests.
    def mediateable_origins
      Settings.origin_admin_groups.to_hash.keys.map(&:to_s).select do |library_origin|
        MediatedPage.exists?(origin: library_origin)
      end
    end
  end

  protected

  def destination_is_a_pickup_library
    return if library_location.pickup_libraries.include?(destination)
    errors.add(:destination, 'is not a valid pickup library')
  end

  # This will currently stil pass if the request has no barcodes.
  # I'm not sure we strongly enforce WHEN requests require barcodes
  # (it seems like it may be variable depending on the record).
  def requested_holdings_exist
    holdings_barcodes = holdings.map(&:barcode)
    return if barcodes.all? { |b| holdings_barcodes.include?(b) }
    errors.add(:base, 'A selected item is not located in the requested location')
  end
end
