# frozen_string_literal: true

module Folio
  class ItemWithStatus < Data.define(:barcode, :request_status)
  end

  # Represents an item returned from the /inventory-hierarchy/items-and-holdings Folio API
  # TODO: This want's a "type" attribute, but I don't know how we get the folio version of a holding type.
  #       See https://github.com/sul-dlss/searchworks_traject_indexer/blob/02192452815de3861dcfafb289e1be8e575cb000/lib/traject/config/sirsi_config.rb#L2379
  class Item < Data.define(:barcode)
    def with_status(request_status)
      ItemWithStatus.new(barcode: barcode, request_status: request_status)
    end

    def self.from_hash(dyn)
      new(barcode: dyn.fetch('barcode'))
    end
  end
end
