###
#  Main Request class.  All other requests use
#  STI and sub-class this main request class.
###
class Request < ActiveRecord::Base
  # We can remove this if Hopkins is no longer mediatable
  OMIT_IP_CHECK_ORIGINS = ['HOPKINS'].freeze
  include Commentable
  include Holdings
  include Requestable
  include DefaultRequestOptions
  include RequestValidations
  include SymphonyRequest

  attr_reader :requested_barcode
  attr_accessor :live_lookup
  scope :recent, -> { order(created_at: :desc) }
  scope :needed_date_desc, -> { order(needed_date: :desc) }
  scope :for_date, ->(date) { where(needed_date: date) }
  scope :for_create_date, lambda { |date|
    where(created_at: Time.zone.parse(date).beginning_of_day..Time.zone.parse(date).end_of_day)
  }
  scope :for_type, ->(request_type) { where(type: request_type) if request_type }

  delegate :hold_recallable?, :mediateable?, :pageable?, :scannable?, to: :library_location

  # Serialized data hash
  store :data, accessors: [
    :ad_hoc_items, :authors, :request_status_data, :item_comment, :public_notes, :page_range,
    :proxy, :request_comment, :section_title, :symphony_response_data
  ], coder: JSON
  serialize :barcodes, Array

  has_many :admin_comments
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
    @searchworks_item ||= SearchworksItem.new(self, live_lookup)
  end

  def send_confirmation!
    ConfirmationMailer.request_confirmation(self).deliver_later if notification_email_address.present?
  end

  def delegate_request!
    case
    when mediateable? then becomes!(MediatedPage)
    when hold_recallable? then becomes!(HoldRecall)
    else becomes!(Page)
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
    case
    when user.webauth_user? then User.find_by_webauth(user.webauth)
    when user.library_id_user? then find_existing_library_id_user
    when user.non_webauth_user? then find_existing_email_user
    end
  end

  def find_existing_library_id_user
    if user.email
      User.find_by(library_id: user.library_id, email: user.email)
    else
      User.find_by_library_id(user.library_id)
    end
  end

  def find_existing_email_user
    User.find_by(email: user.email, library_id: user.library_id).tap do |u|
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
    return user.proxy_access.email_address if proxy? && user.proxy_access.email_address.present?
    user.email_address
  end

  def submit!
    send_to_symphony!
  end

  def barcode_present?
    requested_barcode.present?
  end

  def requested_barcode=(barcode)
    @requested_barcode = barcode if barcode.present?
  end
  alias barcode= requested_barcode=

  def check_remote_ip?
    mediateable? && !OMIT_IP_CHECK_ORIGINS.include?(origin)
  end

  class << self
    # The mediateable_origins will make multiple (efficient) database requests
    # in order to return the array of locations that are both configured as mediateable and have existing requests.
    # Another alternative would be to use (origin_admin_groups & uniq.pluck(:origin)).present? but that will result
    # in a SELECT DISTINCT which could get un-performant with a large table of requests.
    def mediateable_origins
      Settings.origin_admin_groups.to_hash.keys.map(&:to_s).select do |library_or_location|
        MediatedPage.exists?(origin: library_or_location) || MediatedPage.exists?(origin_location: library_or_location)
      end
    end
  end

  def item_status(id)
    ItemStatus.new(self, id)
  end
end
