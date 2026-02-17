# frozen_string_literal: true

###
#  Mailer class to send confirmation emails after requests have
#  been submitted
###
class PatronRequestMailer < ApplicationMailer
  helper :requests
  def confirmation_email(patron_request)
    return unless patron_request.patron_email

    @patron_request = patron_request
    mail(
      to: @patron_request.patron_email,
      from: from_address,
      subject: "#{@patron_request.item_title} - Stanford University Libraries request confirmation"
    )
  end

  def staff_scan_email(patron_request, item_id)
    @patron_request = patron_request
    @item = patron_request.selected_items.find { |i| i.id == item_id }

    mail(
      to: patron_request.scan_service_point&.contact_email || Settings.scan_destinations.default.contact_email,
      from: from_address,
      subject: "Scan Request for #{@patron_request.item_title} (#{@item.barcode})"
    )
  end

  def from_address
    %("Stanford Libraries Requests" <#{@patron_request.contact_info[:email] || 'sul-requests-support@stanford.edu'}>)
  end
end
