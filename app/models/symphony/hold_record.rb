# frozen_string_literal: true

module Symphony
  # A Symphony HoldRecord
  class HoldRecord < Symphony::Base
    def self.find(key)
      new(symphony_client.hold_record_info(key))
    rescue HTTP::Error
      nil
    end

    def status
      fields.dig('status')
    end

    def active?
      %w(PLACED BEING_HELD).include?(status)
    end

    def comment
      fields.dig('comment').to_s
    end

    def item_key
      fields.dig('item', 'key')
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

    def druid
      cdl_comment[1]
    end

    def circ_record_key
      cdl_comment[2].presence
    end

    def cdl_status
      cdl_comment[4]
    end

    def next_up_cdl?
      cdl_status == 'NEXT_UP'
    end

    def cdl_waitlisted?
      cdl_status == 'WAITLIST'
    end

    def patron
      @patron ||= Symphony::Patron.find_by(patron_key: fields.dig('patron', 'key'))
    end

    def cdl_circ_record_checkout_date
      return if cdl_comment[3].blank?

      Time.zone.at(cdl_comment[3].to_i)
    end

    def circ_record
      return unless cdl? && circ_record_key

      @circ_record ||= begin
        record = Symphony::CircRecord.find(circ_record_key)
        return unless record.checkout_date == cdl_circ_record_checkout_date

        record
      end
    end

    def queue_position
      fields.dig('queuePosition')
    end

    def title
      fields.dig('item', 'fields', 'bib', 'fields', 'title')
    end
  end
end