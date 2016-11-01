###
#  Mixin to encapsulate defining if a request is scannable
###
module Scannable
  ITEM_TYPES = %w(BUS-STACKS STKS STKS-MONO STKS-PERI).freeze
  LOCATIONS = %w(BUS-STACKS STACKS).freeze

  def scannable?
    scannable_library? &&
      scannable_location? &&
      includes_scannable_item?
  end

  private

  def scannable_library?
    library == 'SAL3'
  end

  def scannable_location?
    LOCATIONS.include?(location)
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
end
