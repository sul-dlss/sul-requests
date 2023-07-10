# frozen_string_literal: true

###
#  Module to mixin holdings related behavior
###
module Holdings
  def holdings_object
    @holdings_object ||= bib_data&.request_holdings(self) || []
  end

  def holdings
    if persisted? || requested_holdings.present?
      requested_holdings
    else
      all_holdings
    end
  end

  # @return [Array<OpenStruct>] a list of every holding in the requested library/location
  def all_holdings
    holdings_object
  end

  # @return [Array<OpenStruct>] a list of every holding in the requested library/location with the requested barcodes
  def requested_holdings
    requested_item_barcodes = Set.new(Array(requested_barcode || barcodes))

    holdings_object.select { |item| requested_item_barcodes.include? item.barcode }
  end
end
