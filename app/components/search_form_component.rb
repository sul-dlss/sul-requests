# frozen_string_literal: true

# Render a form
class SearchFormComponent < ViewComponent::Base
  def initialize(form_url:, searchable: false, classes: '')
    @form_url = form_url
    @searchable = searchable
    @classes = classes
  end

  attr_reader :form_url, :searchable, :classes

  def origin_libraries
    codes = PatronRequest.distinct.pluck(:origin_location_code).compact_blank
    codes.filter_map { |code| Folio::Types.locations.find_by(code: code)&.library }.uniq
  end

  def destination_libraries
    codes = PatronRequest.distinct.pluck(:service_point_code).compact_blank
    codes.filter_map { |code| Folio::Types.service_points.find_by(code: code) }.uniq
  end
end
