# frozen_string_literal: true

##
# Mailer class to send emails when multiple holds are placed
class MultipleHoldsMailer < ApplicationMailer
  def multiple_holds_notification(options)
    @options = options
    mail(
      to: 'sulcirchelp@stanford.edu',
      subject:
    )
  end

  private

  def subject
    I18n.t(
      'multiple_holds_notification.subject', patron_barcode: @options[:patron_barcode]
    )
  end
end
