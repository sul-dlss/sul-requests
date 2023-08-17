# frozen_string_literal: true

module Symphony
  # Accessing item catalog information from the symphony response
  class CatalogInfo < Symphony::Base
    def self.find(barcode, return_holds: false)
      new(symphony_client.catalog_info(barcode, return_holds:))
    end

    def barcode
      fields.dig('barcode')
    end

    def display_call_number
      fields.dig('call', 'fields', 'dispCallNumber')
    end

    def current_location
      fields.dig('currentLocation', 'key')
    end

    def home_location
      fields.dig('homeLocation', 'key')
    end

    def callkey
      fields.dig('call', 'key')
    end

    def items(refetch: false)
      return to_enum(:items, refetch:) unless block_given?

      Array.wrap(fields.dig('call', 'fields', 'itemList')).each do |record|
        if refetch
          yield Symphony::CatalogInfo.find(record.dig('fields', 'barcode'))
        else
          yield Symphony::CatalogInfo.new(record)
        end
      end
    end
  end
end
