# frozen_string_literal: true

require 'json'

# API for retrieving the current location from a barcode via Symphony Web Services
class SymphonyCurrLocRequest
  include ActiveModel::Model # allows initialization with a hash of attributes

  attr_accessor :barcode

  def current_location
    return '' if json.empty?

    json['fields']['currentLocation']['key']
  rescue NoMethodError => e
    Rails.logger.warn("currentLocation not available for #{barcode}; failed with: #{e}")
    return ''
  end

  private

  def json
    @json ||= begin
      json = SymphonyClient.new.catalog_info(barcode)

      if json.present?
        json
      else
        Rails.logger.warn("Couldn't parse JSON")
        {}
      end
    end
  end
end
