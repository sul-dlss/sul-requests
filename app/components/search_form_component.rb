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
    @origin_libraries ||= PatronRequest.all.map { |elem| Folio::Types.libraries.find_by(code: elem.origin_library_code) }.uniq
  end

  def destination_libraries
    @destination_libraries ||= PatronRequest.all.map do |elem|
      Folio::Types.service_points.find_by(code: elem.service_point_code)
    end.uniq.compact
  end
end
