# frozen_string_literal: true

###
#  Module to mixin holdings related behavior
###
module Holdings
  def holdings_object
    @holdings_object ||= HoldingsRelationshipBuilder.build(bib_data)
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
