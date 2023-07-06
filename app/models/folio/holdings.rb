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
      @all ||= items_in_location.map do |item|
        item.with_status(@request.item_status(item.barcode))
      end
    end

    private

    def items_and_holdings
      @items_and_holdings ||= folio_client.items_and_holdings(instance_id: @instance_id)
    end

    def folio_client
      FolioClient.new
    end

    def items
      items_and_holdings.fetch('items')
    end

    def folio_location_code
      @folio_location_code ||= @request.library_location.folio_location_code
    end

    def items_in_location
      items.map { |dyn| Item.from_hash(dyn) }.select { |item| item.permanent_location == folio_location_code }
    end
  end
end
