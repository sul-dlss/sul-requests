# frozen_string_literal: true

module Symphony
  # Wrapper for a Symphony CircRecord
  class CircRecord < Symphony::Base
    def self.find(key, return_holds: false)
      new(symphony_client.circ_record_info(key, return_holds:))
    rescue HTTP::Error
      nil
    end

    def status
      fields.dig('fields', 'status')
    end

    def item_barcode
      fields.dig('item', 'fields', 'barcode')
    end

    def due_date
      return unless fields.dig('dueDate')

      Time.zone.parse(fields.dig('dueDate'))
    end

    def checkout_date
      return unless fields.dig('checkOutDate')

      Time.zone.parse(fields.dig('checkOutDate'))
    end

    def active?
      status == 'ACTIVE'
    end

    def overdue?
      fields.dig('overdue')
    end

    def patron_barcode
      fields.dig('patron', 'fields', 'barcode')
    end
  end
end
