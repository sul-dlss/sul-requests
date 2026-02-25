# frozen_string_literal: true

module Aeon
  # Wraps Aeon request records
  class RequestGrouping
    include Enumerable

    attr_reader :requests

    delegate :each, to: :requests

    delegate :shipping_option, :title, :call_number, :document_type, :date, :item_url, :reading_room, to: :first

    def initialize(requests)
      @requests = requests
    end
  end
end
