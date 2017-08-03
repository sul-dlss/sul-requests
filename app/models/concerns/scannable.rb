###
#  Mixin to encapsulate defining if a request is scannable
###
module Scannable
  ITEM_TYPES = %w(BUS-STACKS STKS STKS-MONO STKS-PERI).freeze
  LIBRARIES = %w(SAL3).freeze
  LOCATIONS = {
    'SAL3' => %w(BUS-STACKS PAGE-GR STACKS)
  }.freeze

  def scannable?
    scannable_library? &&
      scannable_location? &&
      includes_scannable_item?
  end

  private

  def scannable_library?
    LIBRARIES.include?(library)
  end

  def scannable_location?
    LOCATIONS[library].include?(location)
  end

  def includes_scannable_item?
    request.holdings.any? do |item|
      scannable_item_types.include?(item.type)
    end
  end

  def scannable_item_types
    return ITEM_TYPES unless location
    location_item_types_method_name = "#{location.underscore}_scannable_item_types".to_sym
    return ITEM_TYPES unless respond_to?(location_item_types_method_name, true)
    send(location_item_types_method_name)
  end

  def page_gr_scannable_item_types
    %w(NEWSPAPER NH-INHOUSE).concat(ITEM_TYPES)
  end
end
