# frozen_string_literal: true

##
class CdlWaitlistMailer < ApplicationMailer
  def youre_up(hold_record, circ_record)
    @hold_record = hold_record
    @circ_record = circ_record

    mail(
      to: @hold_record.patron.email,
      subject: "Ready for checkout: #{@hold_record.title}"
    )
  end

  def hold_expired(hold_record_key)
    @hold_record = HoldRecord.find(hold_record_key)
    mail(
      to: @hold_record.patron.email,
      subject: "Hold expired for: #{@hold_record.title}"
    )
  end

  def on_waitlist(hold_record_key)
    @hold_record = HoldRecord.find(hold_record_key)
    mail(
      to: @hold_record.patron.email,
      subject: "Added to waitlist for: #{@hold_record.title}"
    )
  end
end
