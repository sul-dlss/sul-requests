# frozen_string_literal: true

## Stuff
class CdlWaitlistJob < ApplicationJob
  def perform(circ_record_key, checkout_date:)
    circ_record = CircRecord.find(circ_record_key, return_holds: true)

    return unless circ_record.patron_barcode == Settings.cdl.pseudo_patron_id
    return unless checkout_date.nil? || circ_record.checkout_date == checkout_date

    active_hold_record = circ_record.hold_records.find do |record|
      record.active? && record.cdl? && record.circ_record_key == circ_record_key
    end

    return if active_hold_record.present?

    cdl_holds = circ_record.hold_records.select do |record|
      record.active? && record.cdl?
    end

    next_available_hold, remaining_holds = cdl_holds.partition do |hold|
      hold.next_up_cdl? && hold.circ_record_key == circ_record.key
    end

    symphony_client.cancel_hold(next_available_hold.key) if next_available_hold.present?

    # If none or the next available is really the only one, check back in
    return symphony_client.check_in_item(circ_record.item_barcode) if remaining_holds.empty?

    # Figure out which hold is next
    next_up = remaining_holds.min(&:key)

    # Update hold record so its next
    comment = "CDL;#{next_up.druid};#{circ_record.key};;NEXT_UP"
    symphony_client.update_hold(next_up.key, comment: comment)

    symphony_client.edit_circ_record_info(circ_record.key, { dueDate: 30.minutes.from_now.iso8601 })

    # Send patron an email
    CdlWaitlistMailer.youre_up(next_up).deliver_now
  end

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end
end
