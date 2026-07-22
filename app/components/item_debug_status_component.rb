# frozen_string_literal: true

# display admin-level debug information about the item, including the latest API response
class ItemDebugStatusComponent < ViewComponent::Base
  with_collection_parameter :item

  attr_reader :item

  def initialize(item:)
    @item = item
  end
end
