# frozen_string_literal: true

###
#  Main Request class.  All other requests use
#  STI and sub-class this main request class.
###
class Request < ActiveRecord::Base
  include Holdings
  def requires_needed_date?
    false
  end

  attr_reader :requested_barcode
  attr_writer :bib_data

  scope :recent, -> { order(created_at: :desc) }
  scope :needed_date_desc, -> { order(needed_date: :desc) }
  scope :for_date, ->(date) { where(needed_date: date) }
  scope :for_create_date, lambda { |date|
    where(created_at: Time.zone.parse(date).all_day)
  }
  scope :for_type, ->(request_type) { where(type: request_type) if request_type }
  scope :obsolete, lambda { |date|
    where('created_at < ? AND (type != "MediatedPage" OR needed_date < ?)', date, date)
  }

  delegate :hold_recallable?, :mediateable?, :pageable?, :aeon_pageable?, :scannable?, :scannable_only?,
           :default_pickup_destination, :pickup_destinations, :scan_destination, :aeon_site, to: :request_abilities

  delegate :finding_aid, :finding_aid?, to: :bib_data, allow_nil: true

  # Serialized data hash
  store :data, accessors: [
    :ad_hoc_items, :authors, :request_status_data, :item_comment, :public_notes, :page_range,
    :proxy, :request_comment, :section_title, :symphony_response_data, :folio_response_data,
    :reshare_vufind_response_data, :borrow_direct_response_data,
    :illiad_response_data
  ], coder: JSON
  serialize :barcodes, Array

  has_many :admin_comments, as: :request
  has_many :folio_command_logs
  belongs_to :user, autosave: true, optional: true
  accepts_nested_attributes_for :user

  class_attribute :bib_model_class, default: Settings.ils.bib_model.constantize

  before_create do
    self.item_title ||= bib_data&.title
  end

  def paging_origin_library
    # items are already limited to a single permanent location, so we can just grab the first one
    bib_data.items.first&.permanent_location&.details&.dig('pagingSchedule') || origin_library_code
  end

  def library_location
    @library_location ||= LibraryLocation.new(origin, origin_location)
  end

  def active_messages
    library_location.active_messages.for_type(Message.notification_type(self))
  end

  # @returns the model class either sourced from Folio.
  def bib_data
    @bib_data ||= begin
      # Append "a" to the item_id unless it already starts with a letter (e.g. "in00000063826")
      hrid = item_id.start_with?(/\d/) ? "a#{item_id}" : item_id
      bib_model_class.fetch(hrid)
    end
  end

  def send_approval_status!; end

  def delegate_request!
    case
    when aeon_pageable? then becomes!(AeonPage)
    when mediateable? then becomes!(MediatedPage)
    when hold_recallable? then becomes!(HoldRecall)
    else becomes!(Page)
    end
  end

  def item_title
    super || bib_data&.title
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
    when user.sso_user? then User.find_by_sunetid(user.sunetid)
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
    %w(comments page_range section_title authors).filter_map do |field|
      if (data_field = data[field]).present?
        "#{self.class.human_attribute_name(field)}:\n  #{data_field}"
      end
    end
  end

  def proxy?
    proxy == true
  end

  def notification_email_address
    (user&.patron&.proxy_email_address.presence if proxy?) ||
      user&.email_address
  end

  def submit!; end

  def barcode_present?
    requested_barcode.present?
  end

  def requested_barcode=(barcode)
    @requested_barcode = barcode if barcode.present?
  end
  alias barcode= requested_barcode=

  # rubocop:disable Metrics/MethodLength
  # Convert the original origin code to the code used in FOLIO
  def origin_library_code
    case origin
    when 'LANE-MED'
      'LANE'
    when 'HOOVER'
      'HILA'
    when 'HOPKINS'
      'MARINE-BIO'
    when 'MEDIA-MTXT'
      'MEDIA-CENTER'
    when 'RUMSEYMAP'
      'RUMSEY-MAP'
    else
      origin
    end
  end
  # rubocop:enable Metrics/MethodLength

  def destination_library_code
    @destination_library_code ||= Settings.ils.pickup_destination_class.constantize.new(destination).library_code || destination
  end

  def contact_info
    Settings.locations[origin_location]&.contact_info ||
      Settings.libraries[origin_library_code]&.contact_info ||
      Settings.libraries[destination_library_code]&.contact_info ||
      Settings.libraries.default.contact_info
  end

  # NOTE: symphony_response_data + folio_response_data are stored in the JSON in the "data" column
  def ils_response
    @ils_response ||= if folio_response_data
                        FolioResponse.new(folio_response_data || {})
                      else
                        SymphonyResponse.new(symphony_response_data || {})
                      end
  end

  def ils_response_data
    folio_response_data || symphony_response_data || {}
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

  def item_status(id, **)
    ItemStatus.new(self, id, **)
  end

  def request_abilities
    @request_abilities ||= Settings.ils.request_abilities_class.constantize.new(self)
  end
end
