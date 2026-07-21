# frozen_string_literal: true

# Service class to generate service point options for an item or items
class FolioRequestServicePointOptionsService
  attr_reader :items, :selected_service_point_id, :patron

  def initialize(items = [], selected_service_point_id: nil, patron: Folio::NullPatron.new)
    @items = Array(items)
    @selected_service_point_id = selected_service_point_id
    @patron = patron
  end

  def possible_service_points
    @possible_service_points ||= begin
      service_points = []
      # always include the currently selected service point
      service_points += [current_service_point] if current_service_point.present?

      service_points += location_restricted_service_points.select { |sp| patron_is_eligible_for_service_point?(sp) }

      if location_restricted_service_points.empty?
        service_points += default_pickup_service_points
        service_points += additional_pickup_service_points
      end

      service_points.uniq(&:id).sort_by(&:sort_key)
    end
  end

  # Some items are are restricted to specific service points (e.g. PAGE-LP goes to MUSIC or MEDIA-CENTER only).
  # @return [Array<String>]
  def location_restricted_service_points
    @location_restricted_service_points ||= begin
      codes = items.flat_map do |item|
        Array(item.permanent_location.details['pageServicePoints']).pluck('code')
      end.compact.uniq

      codes.map do |code|
        Folio::Types.service_points.find_by(code: code)
      end
    end
  end

  def current_service_point
    Folio::Types.service_points.find_by(id: selected_service_point_id) if selected_service_point_id.present?
  end

  # Returns default service points for all requests
  # @return [Array<String>]
  def default_pickup_service_points
    Folio::Types.service_points.where(is_default_pickup: true).select { |sp| patron_is_eligible_for_service_point?(sp) }
  end

  # Some origin locations (e.g. MEDIA-CENTER) are not a default pickup location, but patrons
  # should be able to pick up the items are the origin.
  # @return [Array<String>]
  def additional_pickup_service_points # rubocop:disable Metrics/AbcSize
    # Find library id for the library with this code
    libraries = items.map { |x| x.effective_location&.library }.uniq

    # things get weird if the items are spread across libraries; for now, let's not worry about that case.
    return [] unless libraries.one?

    library = libraries.first

    service_point = library.primary_service_points.find { |sp| sp.pickup_location? && !sp.is_default_pickup }
    Array(service_point).select { |sp| patron_is_eligible_for_service_point?(sp) }
  end

  def patron_is_eligible_for_service_point?(service_point)
    return true if service_point.nil?

    if patron.present?
      service_point.unpermitted_pickup_groups.exclude?(patron.patron_group_name)
    else
      Settings.allowed_visitor_pickups.include?(service_point.code)
    end
  end
end
