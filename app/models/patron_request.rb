# frozen_string_literal: true

###
#  Main Request class for Requests WC.
###
class PatronRequest < ApplicationRecord
  class_attribute :bib_model_class, default: Settings.ils.bib_model.constantize

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

  def origin_library_code
    folio_location&.library&.code || Folio::Types.libraries.find_by(id: folio_location.library_id)&.code
  end

  private

  def folio_location
    @folio_location ||= Folio::Types.locations.find_by(code: origin_location_code) || items_in_location.first&.permanent_location
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
end
