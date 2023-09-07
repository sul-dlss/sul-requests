# frozen_string_literal: true

module Folio
  ###
  #  Winnows down the entire holdings to just what was requested by the user
  ###
  class Holdings
    include Enumerable

    # @param [Request] request the users request
    def initialize(request, items)
      @request = request
      @items = items
    end

    def each(&block)
      return to_enum(:each) unless block

      items_in_location.each do |item|
        yield item.with_status(request.item_status(item.barcode))
      end
    end

    private

    attr_reader :request

    delegate :location, to: :request

    def items_in_location
      @items.select { |item| item.home_location == location }
    end
  end
end
