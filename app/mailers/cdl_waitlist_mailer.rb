# frozen_string_literal: true

##
class CdlWaitlistMailer < ApplicationMailer
  helper CdlHelper

  def youre_up(hold_record_key)
    @hold_record = HoldRecord.find(hold_record_key)
    @circ_record = @hold_record.circ_record

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

  def on_waitlist(hold_record_key, items: 1)
    @hold_record = HoldRecord.find(hold_record_key)
    return unless @hold_record.exists?

    @queue_position = [@hold_record.queue_position - items, 1].max

    mail(
      to: @hold_record.patron.email,
      subject: "Added to waitlist for: #{@hold_record.title}"
    )
  end
end
