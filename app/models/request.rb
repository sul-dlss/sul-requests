# frozen_string_literal: true

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
  scope :obsolete, lambda { |date|
    where('created_at < ? AND (type != "MediatedPage" OR needed_date < ?)', date, date)
  }

  delegate :hold_recallable?, :mediateable?, :pageable?, :scannable?, :scannable_only?,
           :location_rule, :scannable_location_rule, to: :request_abilities

  # Serialized data hash
  store :data, accessors: [
    :ad_hoc_items, :authors, :request_status_data, :item_comment, :public_notes, :page_range,
    :proxy, :request_comment, :section_title, :symphony_response_data, :borrow_direct_response_data,
    :illiad_response_data
  ], coder: JSON
  serialize :barcodes, Array

  has_many :admin_comments
  belongs_to :user, autosave: true, optional: true
  accepts_nested_attributes_for :user

  before_create do
    self.item_title ||= searchworks_item.title
  end

  def library_location
    @library_location ||= LibraryLocation.new(origin, origin_location)
  end

  def active_messages
    library_location.active_messages.for_type(Message.notification_type(self))
  end

  def searchworks_item
    @searchworks_item ||= SearchworksItem.new(self, live_lookup)
  end

  def bib_info
    @bib_info ||= BibInfo.find(item_id)
  end

  def send_approval_status!
    RequestStatusMailerFactory.for(self).deliver_later if notification_email_address.present?
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
    when user.name_email_user? then find_existing_email_user
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
    return unless user.email

    User.find_by(email: user.email, library_id: user.library_id).tap do |u|
      next unless u

      u.update(name: user.name)
    end
  end

  def data_to_email_s
    data_to_email.join("\n")
  end

  def data_to_email
    %w(comments page_range section_title authors).map do |field|
      if (data_field = data[field]).present?
        "#{self.class.human_attribute_name(field)}:\n  #{data_field}"
      end
    end.compact
  end

  def proxy?
    proxy == true
  end

  def notification_email_address
    (user&.proxy_email_address if proxy?) ||
      user&.email_address
  end

  def submit!
    send_to_symphony_later!
  end

  def barcode_present?
    requested_barcode.present?
  end

  def requested_barcode=(barcode)
    @requested_barcode = barcode if barcode.present?
  end
  alias barcode= requested_barcode=

  def check_remote_ip?
    mediateable?
  end

  def library_id_error?
    errors[:library_id].present?
  end

  def pickup_libraries
    location_rule&.pickup_libraries
  end

  class << self
    # The mediateable_origins will make multiple (efficient) database requests
    # in order to return the array of locations that are both configured as mediateable and have existing requests.
    # Another alternative would be to use (origin_admin_groups & uniq.pluck(:origin)).present? but that will result
    # in a SELECT DISTINCT which could get un-performant with a large table of requests.
    def mediateable_origins
      # This is a super-clunky way to convert data from RailsConfig to something
      # Enumerable, so we can use e.g. #select
      origins = Settings.mediateable_origins.map.to_h.with_indifferent_access

      origins.select do |code, config|
        if config.library_override
          MediatedPage.exists?(origin_location: code.to_s)
        else
          MediatedPage.exists?(origin: code.to_s)
        end
      end
    end
  end

  def item_status(id, **opts)
    ItemStatus.new(self, id, **opts)
  end

  def request_abilities
    @request_abilities ||= RequestAbilities.new(self)
  end
end
