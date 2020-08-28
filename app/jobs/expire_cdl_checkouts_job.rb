# frozen_string_literal: true

# Auto expire CDL Checkouts and holds
class ExpireCdlCheckoutsJob < ApplicationJob
  def perform
    patron = Patron.find_by(library_id: Settings.cdl.pseudo_patron_id)
    patron.checkouts.select(&:overdue?).each do |checkout|
      circ_record = CircRecord.find(checkout.key, return_holds: true)
      hold_records = circ_record.hold_records
      active_hold_record = hold_records.find do |record|
        cdl, _druid, circ_record_key, _ = record.dig('fields', 'comment').split(';')
        return true if cdl == 'CDL' && circ_record_key == checkout.key
      end
      symphony_client.cancel_hold(active_hold_record['key']) if active_hold_record
      symphony_client.check_in_item(circ_record.item_barcode)
      # TODO: waitlist stuff
    end
  end
end
