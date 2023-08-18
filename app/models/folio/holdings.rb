# frozen_string_literal: true

module Folio
  ###
  #  Winnows down the entire holdings to just what was requested by the user
  ###
  class Holdings
    include Enumerable

    # @param [Request] request the users request
    # @param [Array<Folio::Item>] items
    def initialize(request, items)
      @request = request
      @items = items
    end

    def each(&block)
      return to_enum(:each) unless block

      items_in_location.each do |item|
        yield item.with_status(@request.item_status(item.barcode))
      end
    end

    private

    def folio_location_code
      @folio_location_code ||= @request.library_location.folio_location_code
    end

    def items_in_location
      @items.select { |item| item.home_location == folio_location_code }
    end
  end
end
