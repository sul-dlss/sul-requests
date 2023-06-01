# frozen_string_literal: true

module Folio
  # Represents an item returned from the /inventory-hierarchy/items-and-holdings Folio API
  # TODO: This want's a "type" attribute, but I don't know how we get the folio version of a holding type.
  #       See https://github.com/sul-dlss/searchworks_traject_indexer/blob/02192452815de3861dcfafb289e1be8e575cb000/lib/traject/config/sirsi_config.rb#L2379
  Item = Data.define(:barcode, :status, :type, :callnumber, :public_note, :permanent_location, :temporary_location) do
    def with_status(request_status)
      ItemWithStatus.new(barcode:,
                         status:,
                         type:,
                         callnumber:,
                         public_note:,
                         permanent_location:,
                         temporary_location:,
                         request_status:)
    end

    def self.from_hash(dyn)
      new(barcode: dyn.fetch('barcode'),
          status: dyn.fetch('status'),
          type: dyn.fetch('materialType'),
          callnumber: dyn.fetch('callNumber').fetch('callNumber'),
          public_note: dyn.fetch('notes').find { |note| note.fetch('itemNoteTypeName') == 'Public' }&.fetch('note'),
          permanent_location: dyn.dig('location', 'permanentLocation', 'code'),
          temporary_location: dyn.dig('location', 'temporaryLocation', 'code'))
    end
  end
end
