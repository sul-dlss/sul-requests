# frozen_string_literal: true

## Stuff
class CdlWaitlistJob < ApplicationJob
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def perform(circ_record_key, checkout_date:)
    circ_record = CircRecord.find(circ_record_key, return_holds: true)

    unless circ_record.patron_barcode == Settings.cdl.pseudo_patron_id
      cdl_logger("Circ record #{circ_record_key} checked out to non-CDL patron")
      return
    end
    return unless checkout_date.nil? || circ_record.checkout_date == checkout_date

    cdl_hold_records = circ_record.hold_records.select do |record|
      record.active? && record.cdl?
    end

    active_hold_records, remaining_holds = cdl_hold_records.partition do |record|
      record.circ_record_key == circ_record_key
    end

    if active_hold_records.any?
      active_hold_record = active_hold_records.first
      if active_hold_record.comment.include? 'NEXT_UP'
        cdl_logger "Hold #{active_hold_record.key} missed grace period; expiring hold"
      else
        cdl_logger "Hold #{active_hold_record.key} checkout expired; expiring hold"
      end
      symphony_client.cancel_hold(active_hold_record.key)

      comment = active_hold_record.comment.gsub('NEXT_UP', 'MISSED').gsub('ACTIVE', 'EXPIRED')
      symphony_client.update_hold(active_hold_record.key, comment: comment)

      CdlWaitlistMailer.hold_expired(active_hold_record.key).deliver_later if active_hold_record.next_up_cdl?
    end

    cdl_logger "Checking in #{circ_record.item_barcode}"
    symphony_client.check_in_item(circ_record.item_barcode)

    return if remaining_holds.blank?

    cdl_logger "Checking out #{circ_record.item_barcode} for 30 minute grace period; #{remaining_holds.length} in queue"
    checkout = symphony_client.check_out_item(
      circ_record.item_barcode, Settings.cdl.pseudo_patron_id, dueDate: 30.minutes.from_now.iso8601
    )

    new_circ_record = CircRecord.new(checkout&.dig('circRecord'))

    # Figure out which hold is next
    next_up = remaining_holds.min_by(&:key)

    cdl_logger "Marking hold #{next_up.key} as next for #{circ_record.item_barcode}"
    # Update hold record so its next
    comment = "CDL;#{next_up.druid};#{circ_record.key};#{new_circ_record.checkout_date.to_i};NEXT_UP"
    symphony_client.update_hold(next_up.key, comment: comment)

    # Send patron an email
    CdlWaitlistMailer.youre_up(next_up.key).deliver_now
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end
end
