# frozen_string_literal: true

# Render a OTP code input field.
class OtpInputComponent < ViewComponent::Base
  renders_one :label
  attr_reader :name, :form, :length, :value

  def initialize(name:, form: nil, length: 6, value: nil)
    @name = name
    @form = form || ActionView::Helpers::FormBuilder.new(nil, nil, self, {})
    @length = length
    @value = value
  end

  def otp_digit_data
    { 'otp-input-target': 'digit',
      action: 'input->otp-input#shift input->otp-input#focus focus->otp-input#focus input->otp-input#update keydown->otp-input#keydown' }
  end

  def default_label
    'Verification code'
  end
end
