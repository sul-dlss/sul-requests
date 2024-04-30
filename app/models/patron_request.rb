# frozen_string_literal: true

###
#  Main Request class for Requests WC.
###
class PatronRequest < ApplicationRecord
  class_attribute :bib_model_class, default: Settings.ils.bib_model.constantize
  store :data, accessors: [
    :barcodes, :folio_responses, :illiad_response_data, :scan_page_range, :scan_authors, :scan_title, :request_type,
    :proxy, :estimated_delivery, :patron_name
  ], coder: JSON

  delegate :instance_id, :finding_aid, :finding_aid?, to: :bib_data

  before_create do
    self.estimated_delivery = earliest_delivery_estimate(scan: scan?)&.dig('display_date')
  end

  def scan?
    request_type == 'scan'
  end

  def aeon_page?
    items_in_location.any?(&:aeon_pageable?)
  end

  def aeon_site
    items_in_location.filter_map(&:aeon_site).first
  end

  def aeon_form_target
    return unless aeon_page?

    finding_aid? ? finding_aid : Settings.aeon_ere_url
  end

  def submit_later
    SubmitPatronRequestJob.perform_later(self)
  end

  def bib_data
    @bib_data ||= begin
      # Append "a" to the item_id unless it already starts with a letter (e.g. "in00000063826")
      hrid = instance_hrid.start_with?(/\d/) ? "a#{instance_hrid}" : instance_hrid
      bib_model_class.fetch(hrid)
    end
  end

  def item_title
    bib_data&.title
  end

  def items_in_location
    @items_in_location ||= bib_data.items.select do |item|
      if item.effective_location.details['searchworksTreatTemporaryLocationAsPermanentLocation'] == 'true'
        item.effective_location.code == origin_location_code
      else
        item.home_location == origin_location_code
      end
    end
  end

  def selected_items
    items = items_in_location.select { |x| x.barcode.in?(barcodes) || x.id.in?(barcodes) }

    return items.first(1) if request_type == 'scan'

    items
  end

  def pickup_service_point
    selected_pickup_service_point || default_pickup_service_point
  end

  # FOLIO
  def pickup_destinations
    destinations = (default_pickup_service_points + additional_pickup_service_points).uniq if location_restricted_service_point_codes.empty?
    destinations ||= location_restricted_service_point_codes

    return destinations.select { |destination| Settings.allowed_visitor_pickups.include?(destination) } unless patron

    destinations
  end

  # Find service point which is default for this particular campus
  def default_service_point_code
    campus_code = folio_location&.campus&.code
    service_points = if campus_code
                       Folio::Types.service_points.where(is_default_for_campus: campus_code).map(&:code)
                     else
                       []
                     end
    service_points.first || Settings.folio.default_service_point
  end

  def mediateable?
    items_in_location.any?(&:mediateable?)
  end

  def requires_needed_date?
    return false if origin_location_code == 'PAGE-MP' || origin_location_code == 'SAL3-PAGE-MP'

    true
  end

  def use_in_library?
    items_in_location.all? { |item| !item.circulates? }
  end

  def single_location_label
    return 'Must be used in library' if mediateable? || use_in_library?

    'Pickup location'
  end

  def destination_library_code
    pickup_service_point&.library&.code
  end

  def destination_library_pseudopatron_code
    @destination_library_pseudopatron_code ||= begin
      pseudopatron_barcode = Settings.libraries[destination_library_code]&.hold_pseudopatron || raise("no hold pseudopatron for '#{key}'")
      Folio::Patron.find_by(library_id: pseudopatron_barcode)
    end
  end

  def any_items_avaliable?
    items_in_location.any?(&:available?)
  end

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

  def folio_location
    @folio_location ||= Folio::Types.locations.find_by(code: origin_location_code) || items_in_location.first&.permanent_location
  end

  def origin_library_code
    folio_location&.library&.code
  end

  def active_messages
    library_location.active_messages.for_type(scan? ? 'scan' : 'page')
  end

  def barcodes=(arr)
    super(arr.compact_blank)
  end

  def barcode=(barcode)
    self.barcodes = [barcode]
  end

  def holdable_recallable_items
    @holdable_recallable_items ||= items_in_location.filter { |item| item.recallable?(patron) && item.holdable?(patron) }
  end

  def patron
    @patron ||= (Folio::Patron.find_by(patron_key: patron_id) if patron_id)
    @patron ||= Folio::NullPatron.new(display_name: patron_name, email: patron_email)
  end

  def patron=(patron)
    self.patron_id = patron.id
    self.patron_name = patron.display_name
    self.patron_email = patron.email

    @patron = patron
  end

  def contact_info
    Settings.locations[origin_location_code]&.contact_info ||
      Settings.libraries[origin_library_code]&.contact_info ||
      Settings.libraries[destination_library_code]&.contact_info ||
      Settings.libraries.default.contact_info
  end

  def scannable?
    scan_service_point.present? && all_items_scannable?
  end

  def scan_service_point
    @scan_service_point ||= begin
      service_point = items_in_location.filter_map { |item| item.permanent_location.details['scanServicePointCode'] }.first

      Settings.scan_destinations[service_point || :default] || Settings.scan_destinations.default
    end
  end

  def scan_code
    'SCAN'
  end

  def all_items_scannable?
    return false if items_in_location.none?

    items_in_location.all? { |item| scan_service_point.material_types.include?(item.material_type.name) }
  end

  def scan_earliest
    earliest_delivery_estimate(scan: true)
  end

  # Return list of names of individuals who are proxies for this id
  def proxy_group_names
    return nil if patron.blank?

    # Return display name for any proxies where 'requestForSponser' is yes.
    patron.all_proxy_group_info.filter_map do |info|
      return nil unless info['requestForSponsor'].downcase == 'yes'

      # Find the patron corresponding to the Folio user id for the proxy
      proxy_patron = folio_client.find_patron_by_id(info['proxyUserId'])
      # If we find the corresponding FOLIO patron for the proxy, return the display name
      (proxy_patron.present? && proxy_patron&.display_name) || nil
    end
  end

  # Check if the user has selected "yes" on the form with respect to proxy permission
  def proxy?
    proxy == 'share'
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
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
                           SpecIns: 'Hold/Recall Request',
                           LoanTitle: bib_data.title,
                           LoanAuthor: bib_data.author,
                           NotWantedAfter: needed_date.strftime('%Y-%m-%d'),
                           ItemInfo4: destination_library_code
                         })
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def notify_ilb!
    # TODO?
  end

  def request_comments
    return "#{data['patron_name']} <#{patron_email}>" unless patron

    [("(PROXY PICKUP OK; request placed by #{patron.display_name} <#{patron.email}>)" if proxy?)].compact.join("\n")
  end

  private

  def selected_pickup_service_point
    @selected_pickup_service_point ||= Folio::Types.service_points.find_by(code: service_point_code) if service_point_code.present?
  end

  def default_pickup_service_point
    @default_pickup_service_point ||= begin
      service_point = pickup_destinations.one? ? pickup_destinations.first : default_service_point_code
      Folio::Types.service_points.find_by(code: service_point)
    end
  end

  # Returns default service point codes
  def default_pickup_service_points
    Folio::Types.service_points.where(is_default_pickup: true).map(&:code)
  end

  def additional_pickup_service_points
    # Find library id for the library with this code
    library = Folio::Types.libraries.find_by(code: origin_library_code)
    return [] unless library

    service_point_code = library.primary_service_points.find { |sp| sp.pickup_location? && !sp.is_default_pickup }&.code
    Array(service_point_code)
  end

  # Retrieve the service points associated with specific locations
  def location_restricted_service_point_codes
    items_in_location.flat_map do |item|
      Array(item.permanent_location.details['pageServicePoints']).pluck('code')
    end.compact.uniq
  end

  def folio_client
    FolioClient.new
  end

  def library_location
    @library_location ||= LibraryLocation.new(origin_library_code, origin_location_code)
  end
end
