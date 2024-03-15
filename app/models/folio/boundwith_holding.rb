# frozen_string_literal: true

module Folio
  # Represents holding information in a bound with item
  class BoundwithHolding
    attr_reader :callnumber, :title

    def initialize(callnumber:, title:)
      @callnumber = callnumber
      @title = title
    end
  end
end
