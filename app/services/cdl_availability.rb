# frozen_string_literal: true

# Availability check for CDL items
class CdlAvailability
  attr_reader :barcode
  delegate :items, to: :catalog_info

  def initialize(barcode)
    @barcode = barcode
  end

  def self.available(barcode:)
    new(barcode).available
  end

  def available
    earliest_due = nil

    items.each do |item|
      circ_info = symphony_client.circ_information(item.barcode)

      ## A copy is available for CDL, so let it be known
      if ['ON_SHELF', 'ON_RESERVE'].include?(circ_info&.dig('currentStatus'))
        return { available: true, items: items.count, waitlist: catalog_info.hold_records.length }
      end

      item_due_date = parse_due_date(circ_info)

      earliest_due = item_due_date if earliest_due.blank?
      next if item_due_date.blank?

      earliest_due = item_due_date unless earliest_due < item_due_date
    end

    {
      available: false,
      dueDate: earliest_due,
      items: items.count,
      waitlist: catalog_info.hold_records.length
    }
  end

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end

  def parse_due_date(circ_info)
    date = circ_info&.dig('dueDate')
    DateTime.parse(date) if date
  end

  def catalog_info
    @catalog_info ||= CatalogInfo.find(barcode)
  end
end
