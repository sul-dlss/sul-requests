# frozen_string_literal: true

###
#  Mailer class to send approval status emails after requests have
#  been submitted based on either the request type or user error status
###
class ApprovalStatusMailer < ApplicationMailer
  attr_accessor :custom_from_address

  # User ID does not exist
  def approval_status_for_u002(request)
    request_approval_status(request)
  end

  # User is blocked
  def approval_status_for_u003(request)
    request_approval_status(request)
  end

  # User privs are expired
  def approval_status_for_u004(request)
    request_approval_status(request)
  end

  # Symohony returned an error code we don't know how to handle
  def generic_symphony_error(request)
    self.custom_from_address = %("Stanford Libraries Requests" <sul-requests-support@stanford.edu>)

    request_approval_status(request)
  end

  def approval_status_for_holdrecall(request)
    request_approval_status(request)
  end

  def approval_status_for_page(request)
    request_approval_status(request)
  end

  def approval_status_for_scan(request)
    request_approval_status(request)
  end

  private

  def request_approval_status(request)
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
      "approval_status_email.#{@request.class.name.underscore}.subject.#{suffix}",
      title: @request.item_title,
      default: I18n.t("approval_status_email.request.subject.#{suffix}")
    )
  end

  def contact_info
    Settings.locations[@request.origin_location]&.contact_info ||
      Settings.libraries[@request.origin]&.contact_info ||
      Settings.libraries[@request.destination]&.contact_info ||
      Settings.libraries.default.contact_info
  end

  def success_url
    if !@request.user.webauth_user? && @request.is_a?(TokenEncryptable)
      polymorphic_url([:status, @request], token: @request.encrypted_token, only_path: false, protocol: 'https')
    else
      polymorphic_url([:status, @request], only_path: false, protocol: 'https')
    end
  end

  def suffix
    @suffix ||= begin
      if @request.symphony_response.success? || @request.via_borrow_direct?
        'success'
      else
        'failure'
      end
    end
  end
end
