# frozen_string_literal: true

module Folio
  ###
  #  Winnows down the entire holdings to just what was requested by the user
  ###
  class Holdings
    # @param [Request] request the users request
    # @param [Array<#code>] holdings all of the holdings for the requested item
    def initialize(request, holdings)
      @request = request
      @holdings = holdings
    end

    # @return [Array<OpenStruct>] a list of every holding in the requested library/location with the given barcodes
    def where(barcodes: [])
      return [] if barcodes.empty?

      all.select do |item|
        barcodes.include?(item.barcode)
      end
    end

    # @return [Array<OpenStruct>] a list of every holding in the requested library/location
    def all
      return [] if location.blank?

      location.items.map do |item|
        item.request_status = @request.item_status(item.barcode)
        item
      end
    end

    def single_checked_out_item?
      all.one? && all.first.checked_out?
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
