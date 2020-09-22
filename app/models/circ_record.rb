# frozen_string_literal: true

# Wrapper for a Symphony CircRecord
class CircRecord
  def self.find(key)
    symphony_client = SymphonyClient.new
    new(symphony_client.circ_record_info(key))
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

  def checkout_date
    return unless fields.dig('checkOutDate')

    Time.zone.parse(fields.dig('checkOutDate'))
  end

  def active?
    status == 'ACTIVE'
  end

  def hold_records
    fields.dig('item', 'fields', 'bib', 'fields', 'holdRecordList').map { |record| HoldRecord.new(record) }
  end

  def patron_barcode
    fields.dig('patron', 'fields', 'barcode')
  end

  def token; end
end
