# frozen_string_literal: true

module Searchworks
  # A model on the Searchworks holding JSON data
  class HoldingLocation
    def initialize(attributes)
      @code = attributes.fetch('code')
      @items = attributes.fetch('items').map { |location| HoldingItem.new(location) }
    end
    attr_reader :code, :items
  end
end
