# frozen_string_literal: true

module Searchworks
  # A model for the Searchworks holding JSON data
  class Holding
    def initialize(attributes)
      @code = attributes.fetch('code')
      @locations = attributes.fetch('locations').map { |location| HoldingLocation.new(location) }
    end
    attr_reader :code, :locations
  end
end
