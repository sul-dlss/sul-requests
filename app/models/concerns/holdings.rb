###
#  Module to mixin holdings related behavior
###
module Holdings
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

  def all_holdings
    holdings_object.all
  end

  def requested_holdings
    return [] unless requested_barcode.present? || barcodes.present?

    holdings_object.where(barcodes: requested_barcode || barcodes)
  end
end
