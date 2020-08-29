# frozen_string_literal: true

# Wrapper for a Symphony CircRecord
class CircRecord
  def self.find(key, return_holds: false)
    symphony_client = SymphonyClient.new
    new(symphony_client.circ_record_info(key, return_holds: return_holds))
  rescue HTTP::Error
    nil
  end

  attr_reader :record

  def initialize(record = {})
    @record = record
  end

  def exists?
    fields.present?
  end

  def key
    record['key']
  end

  def fields
    record['fields'] || {}
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

  def active?
    status == 'ACTIVE'
  end

  def overdue?
    fields.dig('overdue')
  end

  def hold_records
    fields.dig('item', 'fields', 'bib', 'fields', 'holdRecordList').map { |record| HoldRecord.new(record) }
  end

  def patron_barcode
    fields.dig('patron', 'fields', 'barcode')
  end

  def token; end
end
