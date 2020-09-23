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

  def call_number
    fields.dig('call', 'fields', 'callNumber')
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
end
