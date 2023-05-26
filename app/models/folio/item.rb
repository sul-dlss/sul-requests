# frozen_string_literal: true

module Folio
  class ItemWithStatus < Data.define(:barcode, :request_status)
  end

  # Represents an item returned from the /inventory-hierarchy/items-and-holdings Folio API
  class Item < Data.define(:barcode)
    def with_status(request_status)
      ItemWithStatus.new(barcode: barcode, request_status: request_status)
    end

    def self.from_hash(dyn)
      new(barcode: dyn.fetch('barcode'))
    end
  end
end
