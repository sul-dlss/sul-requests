###
#  Module to mixin holdings related behavior
###
module Holdings
  def holdings_object
    searchworks_item.requested_holdings
  end

  def holdings
    return requested_holdings if persisted? || requested_holdings.present?
    holdings_object.all
  end

  private

  def requested_holdings
    return [] unless requested_barcode.present? || barcodes.present?
    holdings_object.where(barcodes: requested_barcode || barcodes)
  end
end
