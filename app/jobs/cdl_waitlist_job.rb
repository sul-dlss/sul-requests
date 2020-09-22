# frozen_string_literal: true

## CdlWaitlistJob
class CdlWaitlistJob < ApplicationJob
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def perform(circ_record_key, checkout_date:)
    circ_record = CircRecord.find(circ_record_key, return_holds: true)

    return unless circ_record.patron_barcode == Settings.cdl.pseudo_patron_id
    return unless checkout_date.nil? || circ_record.checkout_date == checkout_date

    cdl_hold_records = circ_record.hold_records.select do |record|
      record.active? && record.cdl?
    end

    active_hold_records, remaining_holds = cdl_hold_records.partition do |record|
      record.circ_record_key == circ_record_key
    end

    if active_hold_records.any?
      active_hold_record = active_hold_records.first
      symphony_client.cancel_hold(active_hold_record.key)
      if active_hold_record.next_up_cdl?
        comment = active_hold_record.comment.gsub('NEXT_UP', 'EXPIRED')
        symphony_client.update_hold(active_hold_record.key, comment: comment)
        CdlWaitlistMailer.hold_expired(active_hold_record.key).deliver_later
      end
    end

    symphony_client.check_in_item(circ_record.item_barcode)

    return if remaining_holds.blank?

    next_up = remaining_holds.min_by(&:key)
    CdlCheckoutForWaitlistJob.perform_now(next_up, circ_record.item_barcode)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  def symphony_client
    @symphony_client ||= SymphonyClient.instance
  end
end
