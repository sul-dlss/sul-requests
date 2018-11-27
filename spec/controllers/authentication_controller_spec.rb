# frozen_string_literal: true

require 'rails_helper'

describe AuthenticationController do
  before do
    request.env['HTTP_REFERER'] = 'https://example.com'
  end

  describe 'login' do
    it 'redirects back to the provided referrer' do
      get :login, referrer: '/'
      expect(response).to redirect_to('/')
    end
    it 'redirects back when there is no provided referrer' do
      get :login
      expect(response).to redirect_to('https://example.com')
    end
    it 'has a flash success message informing the user they logged in' do
      get :login
      expect(flash[:success]).to eq 'You have been successfully logged in.'
    end
  end

  describe 'logout' do
    it 'redirects to the Shibboleth logout page' do
      get :logout
      expect(response).to redirect_to('/Shibboleth.sso/Logout')
    end
    it 'has a flash notice message informing the user they logged out' do
      get :logout
      expect(flash[:notice]).to eq 'You have been successfully logged out.'
    end
  end
end
