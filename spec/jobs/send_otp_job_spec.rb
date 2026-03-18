# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendOtpJob do
  let(:email) { 'test@localhost' }

  context 'with a new user' do
    it 'creates a new user if necessary' do
      expect { described_class.perform_now('test+2@localhost') }.to change(User, :count).by(1)
    end
  end

  context 'with an existing user' do
    let!(:user) { User.create!(email:) }

    it 'reuses existing users' do
      expect { described_class.perform_now(email) }.not_to change(User, :count)
    end

    it 'sends an OTP challenge email' do
      expect do
        described_class.perform_now(email)
      end.to send_email(to: email, subject: 'Your one-time code')

      expect(ActionMailer::Base.deliveries.last.body).to match(%r{<strong>\d{6}</strong>})

      code = ActionMailer::Base.deliveries.last.body.raw_source.match(%r{<strong>(\d{6})</strong>})[1]
      expect(user.reload.totp.verify(code)).to be_truthy
    end
  end
end
