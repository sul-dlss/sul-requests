# frozen_string_literal: true

###
#  Mailer class to send confirmation emails after requests have
#  been submitted
###
class PatronRequestMailer < ApplicationMailer
  def confirmation_email(patron_request)
    @request = patron_request
    mail(
      to: @request.patron.email,
      from: from_address,
      subject: "#{@request.item_title} - Stanford University Libraries request confirmation"
    )
  end

  def from_address
    %("Stanford Libraries Requests" <#{contact_info[:email]}>)
  end

  def contact_info
    Settings.libraries[@request.origin_library_code]&.contact_info ||
      Settings.libraries[@request.destination_library_code]&.contact_info ||
      Settings.libraries.default.contact_info || { email: 'sul-requests-support@stanford.edu' }
  end
end