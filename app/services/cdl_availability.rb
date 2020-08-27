# frozen_string_literal: true

# Availability check for CDL items
class CdlAvailability
  attr_reader :barcode

  def initialize(barcode)
    @barcode = barcode
  end

  def self.available(barcode:)
    new(barcode).available
  end

  def available
    circ_response
  end

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end

  def circ_response
    {
      status: circ_info&.dig('currentStatus'),
      dueDate: circ_info&.dig('dueDate')
    }
  end

  def circ_info
    @circ_info ||= symphony_client.circ_information(barcode)
  end
end
