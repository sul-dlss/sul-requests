# frozen_string_literal: true

# Auto expire CDL Checkouts and holds
class ExpireCdlCheckoutsJob < ApplicationJob
  def perform
    return unless Settings.cdl.enabled

    patron = Symphony::Patron.find_by(library_id: Settings.cdl.pseudo_patron_id)
    return if patron.blank?

    patron.checkouts.each do |checkout|
      circ_record = Symphony::CircRecord.find(checkout.key, return_holds: true)

      expire_overdue_checkout(circ_record) if checkout.overdue? || orphaned?(circ_record)
    end
  end

  def expire_overdue_checkout(circ_record)
    cdl_logger "Expiring overdue/orphaned checkout for #{circ_record.key}"
    CdlWaitlistJob.perform_now(circ_record.key, checkout_date: circ_record.checkout_date)
  end

  def orphaned?(circ_record)
    circ_record.hold_records.select(&:active?).none? do |hold|
      hold.cdl? && hold.circ_record_key == circ_record.key && circ_record.checkout_date == hold.cdl_circ_record_checkout_date
    end
  end

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end
end
