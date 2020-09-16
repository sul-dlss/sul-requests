# frozen_string_literal: true

## Stuff
class CdlWaitlistJob < ApplicationJob
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def perform(circ_record_key, checkout_date:)
    circ_record = CircRecord.find(circ_record_key, return_holds: true)

    return unless circ_record.patron_barcode == Settings.cdl.pseudo_patron_id
    return unless checkout_date.nil? || circ_record.checkout_date == checkout_date

    active_hold_record = circ_record.hold_records.find do |record|
      record.active? && record.cdl? && record.circ_record_key == circ_record_key
    end

    if active_hold_record&.next_up_cdl?
      symphony_client.cancel_hold(active_hold_record.key)
      CdlWaitlistMailer.hold_expired(active_hold_record.key).deliver_later
    elsif active_hold_record.present?
      raise(Exceptions::CdlCheckinError, "An active hold exists for #{circ_record.key}")
    end

    remaining_holds = circ_record.hold_records.select do |record|
      record.active? && record.cdl? && !record.next_up_cdl?
    end

    symphony_client.check_in_item(circ_record.item_barcode)

    return if remaining_holds.blank?

    checkout = symphony_client.check_out_item(
      circ_record.item_barcode, Settings.cdl.pseudo_patron_id, dueDate: 30.minutes.from_now.iso8601
    )

    new_circ_record = CircRecord.new(checkout&.dig('circRecord'))

    # Figure out which hold is next
    next_up = remaining_holds.min_by(&:key)

    # Update hold record so its next
    comment = "CDL;#{next_up.druid};#{circ_record.key};#{new_circ_record.checkout_date.to_i};NEXT_UP"
    symphony_client.update_hold(next_up.key, comment: comment)

    # Send patron an email
    CdlWaitlistMailer.youre_up(next_up).deliver_now
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end
end
