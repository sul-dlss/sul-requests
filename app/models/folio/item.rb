# frozen_string_literal: true

module Folio
  CHECKED_OUT = 'Checked out'
  AVAILABLE = 'Available'

  ItemWithStatus = Data.define(:barcode, :status, :request_status, :type, :callnumber) do
    def checked_out?
      status == CHECKED_OUT
    end

    # TODO, is this complete?
    def status_class
      status == AVAILABLE ? 'available' : 'unavailable'
    end

    # TODO, we probably need to handle "Page", which is something Symphony had.
    def status_text
      status
    end

    # TODO, HUH?
    def current_location_code
      'derp'
    end

    # TODO
    def public_note
      'depr'
    end
  end

  # Represents an item returned from the /inventory-hierarchy/items-and-holdings Folio API
  # TODO: This want's a "type" attribute, but I don't know how we get the folio version of a holding type.
  #       See https://github.com/sul-dlss/searchworks_traject_indexer/blob/02192452815de3861dcfafb289e1be8e575cb000/lib/traject/config/sirsi_config.rb#L2379
  Item = Data.define(:barcode, :status, :type, :callnumber) do
    def with_status(request_status)
      ItemWithStatus.new(barcode:,
                         status:,
                         type:,
                         callnumber:, request_status:)
    end

    def self.from_hash(dyn)
      new(barcode: dyn.fetch('barcode'),
          status: dyn.fetch('status'),
          type: dyn.fetch('materialType'),
          callnumber: dyn.fetch('callNumber').fetch('callNumber'))
    end
  end
end
