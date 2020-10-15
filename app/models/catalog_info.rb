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

  def key
    @response['key']
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
    loan_period_key = fields.dig('itemCategory3', 'key')

    time, units = loan_period_key&.scan(/^CDL-(\d+)([DHM])$/)&.first

    return 2.hours unless time && units

    case units
    when 'D'
      time.to_i.days
    when 'M'
      time.to_i.minutes
    else
      time.to_i.hours
    end
  end

  def cdlable?
    home_location == 'CDL'
  end

  def cdl_proxy_hold_item
    @cdl_proxy_hold_item ||= begin
      items.find(&:cdl_preferred_hold?) || fallback_proxy_item
    end
  end

  def cdl_preferred_hold?
    fields.dig('itemCategory4', 'key') == 'CDL-HOLDS'
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

  private

  def fallback_proxy_item
    Honeybadger.notify("No CDL preferred hold item for #{barcode}")

    items.select(&:cdlable?).min_by(&:key) || self
  end
end
