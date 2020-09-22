# frozen_string_literal: true

# Auto expire CDL Checkouts and holds
class ExpireCdlCheckoutsJob < ApplicationJob
  def perform
    return unless Settings.cdl.enabled

    patron = Patron.find_by(library_id: Settings.cdl.pseudo_patron_id)
    patron.checkouts.select(&:overdue?).each do |checkout|
      expire_overdue_checkout(checkout)
    end
  end

  def expire_overdue_checkout(checkout)
    circ_record = CircRecord.find(checkout.key, return_holds: true)
    CdlWaitlistJob.perform_now(checkout.key, checkout_date: circ_record.checkout_date)
  end

  def symphony_client
    @symphony_client ||= SymphonyClient.instance
  end
end
