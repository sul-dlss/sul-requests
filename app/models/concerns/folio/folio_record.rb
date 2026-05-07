# frozen_string_literal: true

module Folio
  # Common accessors into record data
  module FolioRecord
    delegate :library_name,
             :library_code,
             :from_ill?,
             :effective_location,
             :permanent_location,
             to: :record_location

    def catkey
      bib.dig('instance', 'hrid')
    end

    def title
      bib['title']
    end

    def author
      bib['author']
    end

    def call_number
      item.dig('effectiveCallNumberComponents', 'callNumber')
    end

    def shelf_key
      item['effectiveShelvingOrder']
    end

    def barcode
      item['barcode']
    end

    def item_id
      bib['itemId']
    end

    private

    def record_location
      @record_location ||= Folio::RecordLocation.new(item)
    end

    def item
      record.dig('item', 'item') || {}
    end

    # ? FOLIO: not sure the word 'bib' is accurate anymore here / maybe confusing
    def bib
      record['item']
    end
  end
end
