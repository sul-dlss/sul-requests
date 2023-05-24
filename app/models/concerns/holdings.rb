# frozen_string_literal: true

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
    holdings_object.where(barcodes: Array(requested_barcode || barcodes))
  end
end
