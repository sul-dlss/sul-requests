# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionsController do
  before do
    request.env['HTTP_REFERER'] = 'https://test.host/admin'
  end

  describe 'login' do
    it 'redirects back to the provided referrer' do
      allow(request.env['warden']).to receive(:authenticate).and_return(true)
      get :login_by_sunetid, params: { referrer: '/' }
      expect(response).to redirect_to('/')
    end

    it 'redirects back to the provided referrer for registered visitor' do
      allow(request.env['warden']).to receive(:authenticate).and_return(true)
      get :register_visitor, params: { referrer: '/' }
      expect(response).to redirect_to('/')
    end

    it 'displays error flash message if the registered visitor does not authenticate' do
      allow(request.env['warden']).to receive(:authenticate).and_return(false)
      get :register_visitor, params: { referrer: '/' }
      expect(flash[:error]).to eq 'Unable to register visitor. Both name and email are required.'
    end

    it 'redirects back when there is no provided referrer' do
      allow(request.env['warden']).to receive(:authenticate).and_return(true)
      get :login_by_sunetid
      expect(response).to redirect_to('https://test.host/admin')
    end
  end

  describe 'register_visitor with one-time passcode authentication' do
    before do
      allow(Settings.features).to receive(:authenticate_name_email_users).and_return(true)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      allow(controller).to receive(:verify_recaptcha).and_return(recaptcha_passes)
    end

    let(:recaptcha_passes) { true }

    it 'sends the passcode when the reCAPTCHA challenge passes' do
      expect { get :register_visitor, params: { patron_email: 'visitor@example.com' } }
        .to have_enqueued_job(SendOtpJob).with('visitor@example.com')
    end

    context 'when the reCAPTCHA challenge fails' do
      let(:recaptcha_passes) { false }

      it 'does not send the passcode' do
        expect { get :register_visitor, params: { patron_email: 'visitor@example.com' } }
          .not_to have_enqueued_job(SendOtpJob)
      end

      it 'redirects with an error message' do
        get :register_visitor, params: { patron_email: 'visitor@example.com', referrer: '/' }

        expect(response).to redirect_to('/')
        expect(flash[:error]).to eq 'reCAPTCHA verification failed. Please try again.'
      end
    end

    it 'does not send the passcode when the email is missing' do
      expect { get :register_visitor }.not_to have_enqueued_job(SendOtpJob)
      expect(flash[:error]).to eq 'Unable to register visitor. Both name and email are required.'
    end

    it 'does not send the passcode when the email is malformed' do
      expect { get :register_visitor, params: { patron_email: 'not-an-email' } }
        .not_to have_enqueued_job(SendOtpJob)
      expect(flash[:error]).to eq 'Unable to register visitor. Both name and email are required.'
    end
  end

  describe 'register_visitor without one-time passcode authentication' do
    before do
      allow(Settings.features).to receive(:authenticate_name_email_users).and_return(false)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      allow(controller).to receive(:verify_recaptcha).and_return(false)
    end

    it 'does not authenticate the visitor when the reCAPTCHA challenge fails' do
      allow(request.env['warden']).to receive(:authenticate)

      get :register_visitor, params: { name: 'Jane', patron_email: 'visitor@example.com', referrer: '/' }

      expect(request.env['warden']).not_to have_received(:authenticate)
      expect(response).to redirect_to('/')
      expect(flash[:error]).to eq 'reCAPTCHA verification failed. Please try again.'
    end
  end

  describe 'logout' do
    it 'redirects to the Shibboleth logout page' do
      warden.set_user(CurrentUser.new({ 'shibboleth' => true }))
      get :destroy
      expect(response).to redirect_to('/Shibboleth.sso/Logout')
    end

    it 'has a flash notice message informing the user they logged out' do
      warden.set_user(CurrentUser.new({}))
      get :destroy
      expect(flash[:notice]).to eq 'You have been successfully logged out.'
    end
  end
end
