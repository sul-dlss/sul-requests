# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InterstitialController do
  describe 'show' do
    it 'renders a 500 error if there is no redirect_to parameter' do
      get :show
      expect(response).not_to be_successful
      expect(response).to have_http_status :internal_server_error
    end

    it 'renders a 500 error if the redirect_to parameter does not include the original request host' do
      get :show, params: { redirect_to: 'http://google.com?p=http://test.host' }
      expect(response).not_to be_successful
      expect(response).to have_http_status :internal_server_error
    end

    it 'successfully responds when the redirect_to parameter is the same host' do
      get :show, params: { redirect_to: 'http://test.host/some-route' }
      expect(response).to be_successful
      expect(response).to have_http_status :ok
    end

    it 'assigns the decoded url to the @redirect_to variable' do
      get :show, params: { redirect_to: 'http:%2F%2Ftest.host%2Fsome-route' }
      expect(assigns(:redirect_to)).to eq 'http://test.host/some-route'
    end

    it 'handles redirects to non-ascii URLs appropriately' do
      get :show, params: { redirect_to: 'http://test.host/some-route?q=Bedeutung+f%C3%BCr+die+Medi%C3%A4visti' }

      expect(response).to be_successful
    end
  end
end
