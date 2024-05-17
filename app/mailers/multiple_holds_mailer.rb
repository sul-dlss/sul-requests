# frozen_string_literal: true

##
# Mailer class to send emails when multiple holds are placed
class MultipleHoldsMailer < ApplicationMailer
  def multiple_holds_notification(patron_request, item)
    @patron_request = patron_request
    @item = item

    mail(
      to: 'sulcirchelp@stanford.edu',
      subject:
    )
  end

  private

  def subject
    I18n.t(
      'multiple_holds_notification.subject', patron_barcode: @patron_request.destination_library_pseudopatron_library_id
    )
  end
end
