require 'rails_helper'

describe AuthenticationController do
  before do
    request.env['HTTP_REFERER'] = 'https://example.com'
  end
  describe 'login' do
    it 'should redirect back to the provided referrer' do
      get :login, referrer: '/'
      expect(response).to redirect_to('/')
    end
    it 'should redirect back when there is no provided referrer' do
      get :login
      expect(response).to redirect_to('https://example.com')
    end
    it 'should have a flash success message informing the user they logged in' do
      get :login
      expect(flash[:success]).to eq 'You have been successfully logged in.'
    end
  end
  describe 'logout' do
    it 'should redirect back to the provided referrer' do
      get :logout, referrer: '/'
      expect(response).to redirect_to('/')
    end
    it 'should redirect back when there is no provided referrer' do
      get :logout
      expect(response).to redirect_to('https://example.com')
    end
    it 'should have a flash notice message informing the user they logged out' do
      get :logout
      expect(flash[:notice]).to eq 'You have been successfully logged out.'
    end
  end
end
