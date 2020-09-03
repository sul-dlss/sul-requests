# frozen_string_literal: true

##
class CdlWaitlistMailer < ApplicationMailer
  def youre_up(hold_record)
    @hold_record = hold_record
    mail(
      to: hold_record.patron.email,
      subject: subject
    )
  end

  private

  def subject
    'You are up!!!'
  end
end
