# frozen_string_literal: true

# A Symphony HoldRecord
class HoldRecord
  def self.find(key)
    symphony_client = SymphonyClient.new
    new(symphony_client.hold_record_info(key))
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
    fields.dig('status')
  end

  def active?
    %w(PLACED).include?(status)
  end

  def comment
    fields.dig('comment').to_s
  end

  def item_call_key
    fields.dig('item', 'fields', 'call', 'key')
  end

  def cdl?
    cdl_comment[0] == 'CDL'
  end

  def cdl_comment
    comment.split(';')
  end

  def circ_record_key
    cdl_comment[2]
  end

  def cdl_circ_record_checkout_date
    return if cdl_comment[3].blank?

    Time.zone.at(cdl_comment[3].to_i)
  end

  def circ_record
    return unless cdl? && circ_record_key

    @circ_record ||= begin
      record = CircRecord.find(circ_record_key)
      return unless record.checkout_date == cdl_circ_record_checkout_date

      record
    end
  end
end
