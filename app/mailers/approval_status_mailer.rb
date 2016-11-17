###
#  Mailer class to send approval status emails after requests have been submitted
###
class ApprovalStatusMailer < ApplicationMailer
  def request_approval_status(request)
    @request = request
    @status_url = success_url
    @contact_info = formatted_contact_info
    mail(
      to: request.notification_email_address,
      from: from_address,
      subject: subject
    )
  end

  private

  def from_address
    %("Stanford Libraries Requests" <#{contact_info[:email]}>)
  end

  def subject
    I18n.t(
      "approval_status_email.#{@request.class.name.underscore}.subject.#{suffix}",
      title: @request.item_title,
      default: I18n.t("approval_status_email.request.subject.#{suffix}")
    )
  end

  def contact_info
    contact_info_config[@request.origin_location] ||
      contact_info_config[@request.origin] ||
      contact_info_config[@request.destination] ||
      contact_info_config['default']
  end

  def contact_info_config
    SULRequests::Application.config.contact_info
  end

  def formatted_contact_info
    "  #{contact_info[:phone]}\n  #{contact_info[:email]}"
  end

  def success_url
    if !@request.user.webauth_user? && @request.is_a?(TokenEncryptable)
      polymorphic_url([:status, @request], token: @request.encrypted_token)
    else
      polymorphic_url([:status, @request])
    end
  end

  def suffix
    @suffix ||= begin
      if @request.symphony_response.success?
        'success'
      else
        'failure'
      end
    end
  end
end
