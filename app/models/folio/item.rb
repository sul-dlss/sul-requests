# frozen_string_literal: true

module Folio
  CHECKED_OUT = 'Checked out'

  ItemWithStatus = Data.define(:barcode, :status, :request_status, :callnumber) do
    def checked_out?
      status == CHECKED_OUT
    end

    # TODO, huh?
    def status_class
      'available'
    end

    # TODO, huh?
    def status_text
      'dood'
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
  Item = Data.define(:barcode, :status, :callnumber) do
    def with_status(request_status)
      ItemWithStatus.new(barcode:,
                         status:,
                         callnumber:, request_status:)
    end

    def self.from_hash(dyn)
      new(barcode: dyn.fetch('barcode'),
          status: dyn.fetch('status'),
          callnumber: dyn.fetch('callNumber').fetch('callNumber'))
    end
  end
end
