# frozen_string_literal: true

# Availability check for CDL items
class CdlAvailability
  attr_reader :barcode

  CIRC_AVAILABILITY_STATUS_FOR_CDL = ['ON_SHELF', 'ON_RESERVE'].freeze

  def initialize(barcode)
    @barcode = barcode
  end

  def self.available(barcode:)
    new(barcode).available
  end

  # rubocop:disable Metrics/MethodLength
  def available
    earliest_due = nil

    items.each do |item|
      circ_info = symphony_client.circ_information(item.barcode)

      ## A copy is available for CDL, so let it be known
      if CIRC_AVAILABILITY_STATUS_FOR_CDL.include?(circ_info&.dig('currentStatus'))
        return availability_response.merge({ available: true })
      end

      item_due_date = parse_due_date(circ_info)

      earliest_due = item_due_date if earliest_due.blank?
      next if item_due_date.blank?

      earliest_due = item_due_date unless earliest_due < item_due_date
    end

    {
      available: false,
      dueDate: earliest_due
    }.merge(availability_response)
  end
  # rubocop:enable Metrics/MethodLength

  def availability_response
    {
      items: items.count,
      loanPeriod: catalog_info.loan_period,
      nextUps: catalog_info.hold_records.select { |x| x.circ_record_key.present? }.map(&:key),
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
    @catalog_info ||= Symphony::CatalogInfo.find(barcode, return_holds: true)
  end

  def items
    catalog_info.items.select(&:cdlable?)
  end
end
