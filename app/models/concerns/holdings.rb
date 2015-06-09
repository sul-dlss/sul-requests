###
#  Module to mixin holdings related behavior
###
module Holdings
  def holdings_object
    searchworks_item.requested_holdings
  end

  def holdings
    return requested_holdings if requested_holdings.present?
    holdings_object.all
  end

  def barcoded_holdings?
    holdings_object.barcoded_holdings.length > 0
  end

  private

  def requested_holdings
    return unless requested_barcode.present? || barcodes.present?
    holdings_object.where(barcodes: requested_barcode || barcodes)
  end
end
