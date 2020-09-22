# frozen_string_literal: true

## PollForCdlHoldsJob
class PollForCdlHoldsJob < ApplicationJob
  # rubocop:disable Metrics/AbcSize
  def perform
    patron = Patron.find_by(library_id: Settings.cdl.pseudo_patron_id)
    waiting_on_the_shelf = patron.holds.select do |hold|
      hold.status == 'BEING_HELD'
    end
    waiting_on_the_shelf.each do |hold|
      cdl_hold = CatalogInfo.find(hold.item_barcode).hold_records.find(&:cdl?)
      CdlCheckoutForWaitlist.perform_now(cdl_hold, hold.item_barcode) if cdl_hold.present?
      symphony_client.cancel_hold(hold.key)
    end
  end
  # rubocop:enable Metrics/AbcSize

  def symphony_client
    @symphony_client ||= SymphonyClient.instance
  end
end
