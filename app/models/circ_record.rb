# frozen_string_literal: true

# Wrapper for a Symphony CircRecord
class CircRecord < SymphonyBase
  def self.find(key, return_holds: false)
    symphony_client = SymphonyClient.new
    new(symphony_client.circ_record_info(key, return_holds: return_holds))
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

  def hold_records
    Array.wrap(fields.dig('item', 'fields', 'bib', 'fields', 'holdRecordList'))
         .map { |record| HoldRecord.new(record) }
         .select { |record| record.item_call_key == fields.dig('item', 'fields', 'call', 'key') }
  end

  def patron_barcode
    fields.dig('patron', 'fields', 'barcode')
  end
end
