# frozen_string_literal: true

###
#  Main Request class for Requests WC.
###
class PatronRequest < ApplicationRecord
  class_attribute :bib_model_class, default: Settings.ils.bib_model.constantize
  store :data, accessors: [:barcodes, :folio_request_data, :folio_responses], coder: JSON

  delegate :instance_id, to: :bib_data

  def submit_to_ils_later
    SubmitFolioPatronRequestJob.perform_later(self)
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
    items_in_location.select { |x| x.barcode.in?(barcodes) || x.id.in?(barcodes) }
  end

  def pickup_service_point
    Folio::Types.service_points.find_by(code: service_point_code)
  end

  # FOLIO
  def pickup_destinations
    return (default_pickup_service_points + additional_pickup_service_points).uniq if location_restricted_service_point_codes.empty?

    location_restricted_service_point_codes
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

    'Will be delivered to'
  end

  def destination_location
    service_point = pickup_destinations.one? ? pickup_destinations.first : default_service_point_code
    Folio::Types.service_points.find_by(code: service_point)
  end

  def destination_library_code
    destination_location&.library&.code
  end

  def earliest_delivery_estimate
    paging_info = PagingSchedule.for(self).earliest_delivery_estimate
    { 'date' => Date.parse(paging_info.to_s), 'display_date' => paging_info.to_s }
  rescue StandardError
    { 'date' => Time.zone.today, 'display_date' => 'Could not estimate delievery' }
  end

  def folio_location
    @folio_location ||= Folio::Types.locations.find_by(code: origin_location_code) || items_in_location.first&.permanent_location
  end

  def origin_library_code
    folio_location&.library&.code
  end

  def barcode=(barcode)
    self.barcodes = [barcode]
  end

  def holdable_recallable_items
    @holdable_recallable_items ||= items_in_location.filter { |item| item.recallable?(patron) && item.holdable?(patron) }
  end

  def patron
    @patron ||= (Folio::Patron.find_by(patron_key: patron_id) if patron_id)
  end

  def patron=(patron)
    self.patron_id = patron&.id
    @patron = patron
  end

  private

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
end
