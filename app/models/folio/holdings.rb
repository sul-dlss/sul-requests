# frozen_string_literal: true

module Folio
  ###
  #  Winnows down the entire holdings to just what was requested by the user
  ###
  class Holdings
    # @param [Request] request the users request
    # @param [String] instance_id the FOLIO instance_id (a UUID)
    def initialize(request, instance_id)
      @request = request
      @instance_id = instance_id
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

      items_in_location.map do |item|
        item.request_status = @request.item_status(item.barcode)
        item
      end
    end

    def single_checked_out_item?
      all.one? && all.first.checked_out?
    end

    private

    def items_and_holdings
      debugger
      @items_and_holdings ||= folio_client.items_and_holdings(instance_id: @instance_id)
    end

    def folio_client
      FolioClient.new
    end

    def holdings
      items_and_holdings.fetch('holdings')
    end

    def folio_location_code
      @folio_location_code ||= (@request.origin[0,3],@request.origin_location).join('-')
    end

    def items_in_location
    end

    # def library
    #   return if holdings.blank?
    #   debugger
    #   holdings.find do |library|
    #     library.code == @request.origin
    #   end
    # end

    # def location
    #   return if library.blank?
    #   debugger

    #   library.locations.find do |location|
    #     location.code == @request.origin_location
    #   end
    # end
  end
end
