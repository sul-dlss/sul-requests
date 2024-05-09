# frozen_string_literal: true

###
#  Main Request class for Requests WC.
###
class PatronRequest < ApplicationRecord
  class_attribute :bib_model_class, default: Settings.ils.bib_model.constantize
  store :data, accessors: [
    :barcodes, :folio_responses, :illiad_response_data, :scan_page_range, :scan_authors, :scan_title,
    :proxy, :for_sponsor, :for_sponsor_id, :estimated_delivery, :patron_name, :item_title, :requested_barcodes, :item_mediation_data
  ], coder: JSON

  delegate :instance_id, :finding_aid, :finding_aid?, to: :bib_data

  validates :instance_hrid, presence: true
  validates :request_type, inclusion: { in: %w[scan pickup mediated mediated/approved mediated/done] }
  validates :scan_title, presence: true, on: :create, if: :scan?
  validate :pickup_service_point_is_valid, on: :create, unless: :scan?
  validate :needed_date_is_valid, on: :create
  validate :for_sponsor_id_is_valid, on: :create

  scope :obsolete, lambda { |date|
    where('(created_at < ?) AND (needed_date IS NULL OR needed_date < ?)', date, date)
  }
  scope :mediated, -> { where(request_type: ['mediated', 'mediated/approved', 'mediated/done']) }
  scope :unapproved, -> { where(request_type: ['mediated']) }
  scope :completed, lambda {
    where(request_type: ['mediated/approved', 'mediated/done']).order(needed_date: :desc)
  }
  scope :archived, -> { where('needed_date < ?', Time.zone.today).order(needed_date: :desc) }
  scope :for_origin, lambda { |origin|
                       where(origin_location_code: [origin, *(Folio::Types.libraries.find_by(code: origin)&.locations&.map(&:code) || [])])
                     }

  scope :for_date, ->(date) { where(needed_date: date) }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_create_date, lambda { |date|
    where(created_at: Time.zone.parse(date).all_day)
  }
  has_many :admin_comments, as: :request, dependent: :delete_all

  attr_writer :bib_data

  before_create do
    self.request_type = 'mediated' if mediateable? && !request_type.start_with?('mediated')
    self.item_title = bib_data&.title
    self.estimated_delivery = earliest_delivery_estimate(scan: scan?)&.dig('display_date')
  end

  # @!group Attribute methods
  def barcode=(barcode)
    self.barcodes = [barcode]
  end

  # Remove any empty strings from the barcodes array
  def barcodes=(arr)
    super(arr.compact_blank)
  end

  # Evaluate if this is a title only request
  def title_only?
    bib_data.items.empty?
  end

  # Clean up memoized variables that depend on the service point code
  def service_point_code=(value)
    @selected_pickup_service_point = nil
    @destination_library_pseudopatron = nil
    super
  end

  def type
    return 'Scan' if scan?

    if fulfillment_type == 'hold'
      'Hold'
    elsif fulfillment_type == 'recall'
      'Recall'
    else
      'Page'
    end
  end

  def scan?
    request_type == 'scan'
  end

  # Check if the user has selected "yes" on the form with respect to proxy permission
  def proxy?
    proxy == 'share'
  end

  # Check if the user has selected a sponsor on the form for making the request on behalf of their sponsor
  def for_sponsor?
    for_sponsor == 'share'
  end

  def folio_responses
    super || {}
  end

  def item_mediation_data
    super || {}
  end
  # @!endgroup

  # @!group Origin + destination accessors

  # Get the FOLIO location object for the origin location code
  # @return [Folio::Location]
  def folio_location
    @folio_location ||= Folio::Types.locations.find_by(code: origin_location_code) || selectable_items.first&.permanent_location
  end

  # @deprecated Used by the paging schedule; new code should use folio_location instead
  # @return [String] the code of the origin location
  def origin_library_code
    folio_location&.library&.code
  end

  # @deprecated Used by the paging schedule; new code should use pickup_service_point instead
  # @return [String] the code of the destination pickup location
  def destination_library_code
    pickup_service_point&.library&.code
  end

  # Used when placing requests for users without a FOLIO patron account (e.g. name/email users)
  # @return [Folio::Patron] the pseudopatron for the destination pickup location
  def destination_library_pseudopatron
    @destination_library_pseudopatron ||= begin
      pseudopatron_barcode = Settings.libraries[destination_library_code]&.hold_pseudopatron || raise("no hold pseudopatron for '#{key}'")
      Folio::Patron.find_by(library_id: pseudopatron_barcode)
    end
  end

  # @return [Array<Message>] Location-specific broadcast messages that impact this request
  def active_messages
    library_location.active_messages.for_type(scan? ? 'scan' : 'page')
  end

  # Figure out the best contact info for the patron to use for this request; usually
  # the origin location if it's public-facing, or the destination library if it's not.
  # @return [Hash] phone + email

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def contact_info
    return Settings.libraries[scan_code]&.contact_info if request_type == 'scan'

    Settings.locations[origin_location_code]&.contact_info ||
      Settings.libraries[origin_library_code]&.contact_info ||
      Settings.libraries[destination_library_code]&.contact_info ||
      Settings.libraries.default.contact_info
  end

  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  # @return [Folio::ServicePoint] the selected (or default) service point for pickup
  def pickup_service_point
    selected_pickup_service_point || default_pickup_service_point
  end

  # The available pickup service points are:
  # - the default service points for any request
  # - a service point associated with the origin library (e.g. MEDIA-CENTER, which is not a default pickup location)
  # But some items are restricted to specific service points.
  # Finally, visitors are restricted to a subset of service points.
  #
  # @return [Array<String>] the list of service point codes that are valid for this request
  def pickup_destinations
    if location_restricted_service_point_codes.empty?
      destinations = (default_pickup_service_points_codes + additional_pickup_service_points_codes).uniq
    end
    destinations ||= location_restricted_service_point_codes

    return destinations.select { |destination| Settings.allowed_visitor_pickups.include?(destination) } if patron.blank?

    destinations
  end

  # Find service point which is default for this particular campus
  # @return [Folio::ServicePoint]
  def default_service_point_code(allowed_service_points: pickup_destinations)
    @default_service_point_code ||= if default_service_point_for_campus.in? allowed_service_points
                                      default_service_point_for_campus
                                    else
                                      allowed_service_points.first
                                    end
  end

  # @!endgroup

  # @!group FOLIO instance + items
  def submit_later
    SubmitPatronRequestJob.perform_later(self)
  end

  # @return [Folio::Instance]
  def bib_data
    @bib_data ||= begin
      # Append "a" to the item_id unless it already starts with a letter (e.g. "in00000063826")
      hrid = instance_hrid.start_with?(/\d/) ? "a#{instance_hrid}" : instance_hrid
      bib_model_class.fetch(hrid)
    end
  end

  # @return [String] the title of the item
  def item_title
    super || bib_data&.title
  end

  # Item stuff

  # @return [Array<Folio::Item>] the items in the origin location
  def items_in_location
    @items_in_location ||= bib_data.items.select do |item|
      if item.effective_location.details['searchworksTreatTemporaryLocationAsPermanentLocation'] == 'true'
        item.effective_location.code == origin_location_code
      else
        item.home_location == origin_location_code
      end
    end
  end

  # @return [Array<Folio::Item>] the items the patron can select from (based on the location or the barcodes passed in initially)
  def selectable_items
    if requested_barcodes&.any?
      items_in_location.select { |x| x.barcode&.in?(requested_barcodes) || x.id.in?(requested_barcodes) }
    else
      items_in_location
    end
  end

  # @return [Array<Folio::Item>] the items the patron has selected
  def selected_items
    return [] unless barcodes&.any?

    items = items_in_location.select { |x| x.barcode.in?(barcodes) || x.id.in?(barcodes) }

    return items.first(1) if request_type == 'scan'

    items
  end

  # @return [Array<Folio::Item>] the items that are holdable and recallable by the patron
  def holdable_recallable_items
    @holdable_recallable_items ||= selectable_items.filter { |item| item.recallable?(patron) && item.holdable?(patron) }
  end

  # @return [Boolean] whether any items are available (e.g. for paging, so we can estimate delivery dates)
  def any_items_avaliable?
    selectable_items.any?(&:available?)
  end

  # @return [Hash] the earliest delivery estimate for the request
  def earliest_delivery_estimate(scan: false)
    if any_items_avaliable?
      paging_info = PagingSchedule.for(self, scan:).earliest_delivery_estimate
      { 'date' => Date.parse(paging_info.to_s), 'display_date' => paging_info.to_s }
    else
      { 'date' => Time.zone.today, 'display_date' => 'No date/time estimate' }
    end
  rescue StandardError
    { 'date' => Time.zone.today, 'display_date' => 'No date/time estimate' }
  end

  # @return [Boolean] whether the request should be mediated before being placed in FOLIO
  def mediateable?
    selectable_items.any?(&:mediateable?)
  end

  # Paging requests don't require a needed date, however most mediated pages need to know when
  # the patron expects to visit the library to use the material. Hold/recall requests also need
  # a date so staff can expire old requests.
  # @return [Boolean] whether the request requires a needed date from the patron
  def requires_needed_date?
    return false if mediateable? && (origin_location_code == 'PAGE-MP' || origin_location_code == 'SAL3-PAGE-MP')

    mediateable? || selected_items.any? { |item| item.recallable?(patron) || item.holdable?(patron) }
  end

  def use_in_library?
    selectable_items.all? { |item| !item.circulates? }
  end

  def location_label
    return 'In library use only' if mediateable? || use_in_library?
    return 'Pickup location' if pickup_destinations.one?

    'Preferred pickup location'
  end

  # @!endgroup

  # @!group Patron accessors

  # @return [Folio::Patron] the patron associated with the request
  def patron
    @patron ||= (Folio::Patron.find_by(patron_key: patron_id) if patron_id)
    @patron ||= Folio::NullPatron.new(display_name: patron_name, email: patron_email)
  end

  # Also set patron information directly on this request; mostly used for visitors without
  # FOLIO accounts, but could also be useful for mediated pages or debugging.
  def patron=(patron)
    if patron
      self.patron_id = patron.id
      self.patron_name = patron.display_name
      self.patron_email = patron.email
    end

    @patron = patron
  end

  # @return [String] comments to include in the FOLIO request
  def request_comments
    return "#{patron_name} <#{patron_email}>" if patron.blank?

    [("(PROXY PICKUP OK; request placed by #{patron.display_name} <#{patron.email}>)" if proxy?),
     ("(PROXY PICKUP OK; request placed by #{patron.display_name} <#{patron.email}>" if for_sponsor?)].compact.join("\n")
  end

  # @!endgroup

  # @!group Non-FOLIO fulfillment

  # A request is fulfilled through Aeon if any of the items are "Aeon pageable" (e.g. are in
  # a location with a `pageAeonSite` detail)
  def aeon_page?
    selectable_items.any?(&:aeon_pageable?)
  end

  # @return [String] the Aeon site code for the items in the request
  def aeon_site
    selectable_items.filter_map(&:aeon_site).first
  end

  def aeon_form_target
    return unless aeon_page?

    finding_aid? ? finding_aid : Settings.aeon_ere_url
  end

  # For the reading room information, we need to check if 'ARS' is in the location details
  # for the library. An example is SAL3, which should show the ARS reading room information
  # and so should return ARS as the library code for the reading room text block.
  # This logic will be extended in the future to cover any location that has a pageAeonSite value.
  def aeon_reading_room_code
    details = folio_location.details
    details.key?('pageAeonSite') && details['pageAeonSite'] == 'ARS' ? 'ARS' : origin_library_code
  end

  # Get the name of the reading room where Aeon items will be prepared for use.
  # A custom name can be set in the settings for each library; otherwise the
  # default is the library name followed by "Reading Room".
  def aeon_reading_room_name
    library = Settings.libraries[aeon_reading_room_code] || Settings.libraries.default
    library.reading_room_label || "#{library['label']} Reading Room"
  end

  # Scan stuff
  def scannable?
    scan_service_point.present? && all_items_scannable?
  end

  def scan_service_point
    @scan_service_point ||= begin
      service_point = selectable_items.filter_map { |item| item.permanent_location.details['scanServicePointCode'] }.first

      Settings.scan_destinations[service_point || :default] || Settings.scan_destinations.default
    end
  end

  def scan_code
    'SCAN'
  end

  def all_items_scannable?
    return false if selectable_items.none?

    selectable_items.all? { |item| scan_service_point.material_types.include?(item.material_type.name) }
  end

  def scan_earliest
    earliest_delivery_estimate(scan: true)
  end

  # ILLiad stuff
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize

  # All scan requests and some hold/recalls (not fulfilled through FOLIO) are
  # directed to ILLiad for fulfillment.
  # @return [Hash] the parameters to send to ILLiad for the request
  def illiad_request_params(item)
    default_values = {
      ProcessType: 'Borrowing',
      AcceptAlternateEdition: false,
      Username: patron.username,
      UserInfo1: patron.blocked? ? 'Blocked' : nil,
      ISSN: bib_data.isbn,
      LoanPublisher: bib_data.publisher,
      LoanPlace: bib_data.pub_place,
      LoanDate: bib_data.pub_date,
      LoanEdition: bib_data.edition,
      ESPNumber: bib_data.oclcn,
      CitedIn: bib_data.view_url,
      CallNumber: item&.callnumber,
      ILLNumber: item&.barcode,
      ItemNumber: item&.barcode,
      PhotoJournalVolume: item&.enumeration
    }

    if request_type == 'scan'
      return default_values.merge({
                                    RequestType: 'Article',
                                    SpecIns: 'Scan and Deliver Request',
                                    PhotoJournalTitle: bib_data.title,
                                    PhotoArticleAuthor: bib_data.author,
                                    Location: origin_library_code,
                                    ReferenceNumber: origin_location_code,
                                    PhotoArticleTitle: scan_title,
                                    PhotoJournalInclusivePages: scan_page_range
                                  })
    end

    default_values.merge({
                           RequestType: 'Loan',
                           SpecIns: 'SearchWorks Request',
                           LoanTitle: bib_data.title,
                           LoanAuthor: bib_data.author,
                           NotWantedAfter: needed_date.strftime('%Y-%m-%d'),
                           ItemInfo4: destination_library_code
                         })
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # @!endgroup
  # @!group Mediated pages

  # return [Array<Date>] the next N dates that have requests for the origin location
  def self.needed_dates_for_origin_after_date(origin:, date:, count: 3)
    mediated.for_origin(origin).where('needed_date > ?', date).distinct.pluck(:needed_date).sort.take(count)
  end

  def unapproved?
    request_type == 'mediated'
  end

  def approved?
    request_type == 'mediated/approved'
  end

  def marked_as_done?
    request_type == 'mediated/done'
  end

  # @return Hash
  def item_status(item_id)
    item_mediation_data[item_id] || {}
  end

  def update_item_status(item_id, **status)
    update(item_mediation_data: item_mediation_data.merge({ item_id => item_status(item_id).merge(status) }))

    update(request_type: 'mediated/approved') if selected_items.all? { |x| item_status(x.id)['approved'] }
  end

  # Mark the specified item as approved and submit the request to FOLIO
  def approve_item(item_id, approver:)
    update_item_status(item_id, approved: true, approver: approver.sunetid,
                                approved_at: Time.zone.now)

    folio_response = SubmitFolioPatronRequestJob.perform_now(self, item_id)

    update(folio_responses: folio_responses.merge(item_id => folio_response))
  end

  def notify_mediator!
    return unless mediator_notification_email_address.present? && Settings.features.mediator_email

    MediationMailer.mediator_notification(self).deliver_later
  end

  def mediator_notification_email_address
    Rails.application.config.mediator_contact_info.fetch(
      origin_library_code,
      Rails.application.config.mediator_contact_info.fetch(origin_location_code, {})
    )[:email]
  end
  # @!endgroup

  private

  # @return [Folio::ServicePoint] the selected service point for pickup
  def selected_pickup_service_point
    @selected_pickup_service_point ||= Folio::Types.service_points.find_by(code: service_point_code) if service_point_code.present?
  end

  # @return [Folio::ServicePoint] the default service point for pickup
  def default_pickup_service_point
    @default_pickup_service_point ||= begin
      service_point = pickup_destinations.one? ? pickup_destinations.first : default_service_point_code
      Folio::Types.service_points.find_by(code: service_point)
    end
  end

  # Returns default service point codes for all requests
  # @return [Array<String>]
  def default_pickup_service_points_codes
    Folio::Types.service_points.where(is_default_pickup: true).map(&:code)
  end

  # Some origin locations (e.g. MEDIA-CENTER) are not a default pickup location, but patrons
  # should be able to pick up the items are the origin.
  # @return [Array<String>]
  def additional_pickup_service_points_codes
    # Find library id for the library with this code
    library = Folio::Types.libraries.find_by(code: origin_library_code)
    return [] unless library

    service_point_code = library.primary_service_points.find { |sp| sp.pickup_location? && !sp.is_default_pickup }&.code
    Array(service_point_code)
  end

  # Some items are are restricted to specific service points (e.g. PAGE-LP goes to MUSIC or MEDIA-CENTER only).
  # @return [Array<String>]
  def location_restricted_service_point_codes
    selectable_items.flat_map do |item|
      Array(item.permanent_location.details['pageServicePoints']).pluck('code')
    end.compact.uniq
  end

  # @return [FolioClient]
  def folio_client
    FolioClient.new
  end

  # @return [LibraryLocation]
  def library_location
    @library_location ||= LibraryLocation.new(origin_library_code, origin_location_code)
  end

  def default_service_point_for_campus
    campus_code = folio_location&.campus&.code
    service_points = if campus_code
                       Folio::Types.service_points.where(is_default_for_campus: campus_code).map(&:code)
                     else
                       []
                     end
    service_points.first || Settings.folio.default_service_point
  end

  # Validate that the chosen service point is a valid pickup location for the items
  def pickup_service_point_is_valid
    return if pickup_service_point.code.in? pickup_destinations

    errors.add(:service_point_code, 'is not a valid pickup library')
  end

  # Validate that the needed date is present + valid for requests that require it
  def needed_date_is_valid
    return unless requires_needed_date?

    return errors.add(:needed_date, 'Date cannot be blank') if needed_date.blank?

    errors.add(:needed_date, 'Date cannot be earlier than today') if needed_date < Time.zone.today
  end

  def for_sponsor_id_is_valid
    return unless for_sponsor_id && for_sponsor?

    errors.add(:for_sponsor_id, 'Invalid sponsor') unless patron.sponsors.any? { |sponsor| sponsor.id == for_sponsor_id }
  end
end
