# frozen_string_literal: true

# Auto expire CDL Checkouts and holds
class ExpireCdlCheckoutsJob < ApplicationJob
  def perform
    patron = Patron.find_by(library_id: Settings.cdl.pseudo_patron_id)
    patron.checkouts.select(&:overdue?).each do |checkout|
      circ_record = CircRecord.find(checkout.key, return_holds: true)
      active_hold_record = circ_record.hold_records.find do |record|
        record.active? && record.cdl? && record.circ_record_key == checkout.key
      end
      symphony_client.cancel_hold(active_hold_record.key) if active_hold_record
      symphony_client.check_in_item(circ_record.item_barcode)
      # TODO: waitlist stuff
    end
  end

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end
end
