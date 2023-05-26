# frozen_string_literal: true

###
#  Module to mixin holdings related behavior
###
module Holdings
  def holdings_object
    @holdings_object ||= if bib_data.is_a? Folio::BibData
      debugger
                           Folio::Holdings.new(self, bib_data.holdings)
                         else
                           Searchworks::Holdings.new(self, bib_data.holdings)
                         end
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
