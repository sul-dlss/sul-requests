# frozen_string_literal: true

## CdlCheckoutForWaitlistJob
class CdlCheckoutForWaitlistJob < ApplicationJob
  # rubocop:disable Metrics/AbcSize
  def perform(hold_record, barcode)
    checkout = symphony_client.check_out_item(
      barcode, Settings.cdl.pseudo_patron_id, dueDate: 30.minutes.from_now.iso8601
    )

    new_circ_record = CircRecord.new(checkout&.dig('circRecord'))

    # Update hold record so its next
    comment = "CDL;#{hold_record.druid};#{new_circ_record.key};#{new_circ_record.checkout_date.to_i};NEXT_UP"
    symphony_client.update_hold(hold_record.key, comment: comment)

    # Send patron an email
    CdlWaitlistMailer.youre_up(hold_record, new_circ_record).deliver_now
  end
  # rubocop:enable Metrics/AbcSize

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end
end
