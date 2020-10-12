# frozen_string_literal: true

# Accessing item catalog information from the symphony response
class CatalogInfo
  def self.find(barcode)
    new(SymphonyClient.new.catalog_info(barcode))
  end

  attr_reader :response

  def initialize(response)
    @response = response
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

  def fields
    (@response || {}).dig('fields') || {}
  end

  def callkey
    fields.dig('call', 'key')
  end

  def loan_period
    (fields.dig('itemCategory3', 'key')&.scan(/^CDL-(\d+)H$/)&.flatten&.first&.to_i || 2).hours
  end

  def cdlable?
    home_location == 'CDL'
  end

  def items
    return to_enum(:items) unless block_given?

    Array.wrap(fields.dig('call', 'fields', 'itemList')).each do |record|
      yield CatalogInfo.new(record)
    end
  end

  def hold_records
    Array.wrap(fields.dig('bib', 'fields', 'holdRecordList')&.map { |record| HoldRecord.new(record) }&.select do |record|
      callkey == record.item_call_key && record.active?
    end)
  end
end
