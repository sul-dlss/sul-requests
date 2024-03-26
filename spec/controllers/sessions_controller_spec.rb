# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionsController do
  before do
    request.env['HTTP_REFERER'] = 'https://test.host/admin'
  end

  describe 'login' do
    it 'redirects back to the provided referrer' do
      warden.set_user({})
      get :login_by_sunetid, params: { referrer: '/' }
      expect(response).to redirect_to('/')
    end

    it 'redirects back when there is no provided referrer' do
      warden.set_user({})
      get :login_by_sunetid
      expect(response).to redirect_to('https://test.host/admin')
    end
  end

  describe 'logout' do
    it 'redirects to the Shibboleth logout page' do
      warden.set_user({ shibboleth: true })
      get :destroy
      expect(response).to redirect_to('/Shibboleth.sso/Logout')
    end

    it 'has a flash notice message informing the user they logged out' do
      warden.set_user({})
      get :destroy
      expect(flash[:notice]).to eq 'You have been successfully logged out.'
    end
  end
end
