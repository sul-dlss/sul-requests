# frozen_string_literal: true

module Searchworks
  ###
  #  Winnows down the entire holdings to just what was requested by the user
  ###
  class Holdings
    include Enumerable

    # @param [Request] request the users request
    # @param [Array<Searchworks::Holding>] holdings all of the holdings for the requested item
    def initialize(request, holdings)
      @request = request
      @holdings = holdings
    end

    def each(&block)
      return to_enum(:each) unless block

      location&.items&.each do |item|
        item.request_status = @request.item_status(item.barcode)
        yield item
      end
    end

    private

    def library
      return if @holdings.blank?

      @holdings.find do |library|
        library.code == @request.origin
      end
    end

    def location
      return if library.blank?

      library.locations.find do |location|
        location.code == @request.origin_location
      end
    end
  end
end
