# frozen_string_literal: true

class OtpInputComponentPreview < ViewComponent::Preview
  layout 'lookbook'

  def default
    render OtpInputComponent.new(name: 'otp_code', form: nil)
  end
end
