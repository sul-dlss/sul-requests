# frozen_string_literal: true

###
#  Module to mixin holdings related behavior
###
module Holdings
  delegate :mhld, to: :holdings_object

  def holdings_object
    searchworks_item.requested_holdings
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
    holdings_object.all
  end

  # @return [Array<OpenStruct>] a list of every holding in the requested library/location with the requested barcodes
  def requested_holdings
    holdings_object.where(barcodes: Array(requested_barcode || barcodes))
  end
end
