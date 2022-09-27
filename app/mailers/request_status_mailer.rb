# frozen_string_literal: true

###
#  Mailer class to send approval status emails after requests have
#  been submitted based on either the request type or user error status
###
class RequestStatusMailer < ApplicationMailer
  attr_accessor :custom_from_address

  # User is blocked
  def request_status_for_u003(request)
    request_status(request)
  end

  # User privs are expired
  def request_status_for_u004(request)
    request_status(request)
  end

  # Symohony returned an error code we don't know how to handle
  def generic_symphony_error(request)
    self.custom_from_address = %("Stanford Libraries Requests" <sul-requests-support@stanford.edu>)

    request_status(request)
  end

  def request_status_for_holdrecall(request)
    request_status(request)
  end

  def request_status_for_page(request)
    request_status(request)
  end

  def request_status_for_scan(request)
    request_status(request)
  end

  def request_status_for_mediatedpage(request)
    request_status(request)
  end

  private

  def request_status(request)
    @request = request
    @status_url = success_url
    @contact_info = contact_info
    mail(
      to: request.notification_email_address,
      from: from_address,
      subject: subject
    )
  end

  def from_address
    custom_from_address || %("Stanford Libraries Requests" <#{contact_info[:email]}>)
  end

  def subject
    I18n.t(
      "request_status_email.#{@request.class.name.underscore}.#{@request.origin}.subject.#{suffix}",
      title: @request.item_title,
      default: [
        :"request_status_email.#{@request.class.name.underscore}.subject.#{suffix}",
        :"request_status_email.request.subject.#{suffix}"
      ]
    )
  end

  def contact_info
    Settings.locations[@request.origin_location]&.contact_info ||
      Settings.libraries[@request.origin]&.contact_info ||
      Settings.libraries[@request.destination]&.contact_info ||
      Settings.libraries.default.contact_info
  end

  def success_url
    if !@request.user.sso_user? && @request.is_a?(TokenEncryptable)
      polymorphic_url([:status, @request], token: @request.encrypted_token, only_path: false, protocol: 'https')
    else
      polymorphic_url([:status, @request], only_path: false, protocol: 'https')
    end
  end

  def suffix
    @suffix ||= if @request.symphony_response.all_successful? || @request.via_borrow_direct? || @request.is_a?(MediatedPage)
                  'success'
                else
                  'failure'
                end
  end
end
