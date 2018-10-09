require 'rails_helper'

describe InterstitialController do
  describe 'show' do
    it 'renders a 500 error if there is no redirect_to parameter' do
      get :show
      expect(response).not_to be_success
      expect(response.status).to eq 500
    end

    it 'renders a 500 error if the redirect_to parameter does not include the original request host' do
      get :show, redirect_to: 'http://google.com?p=http://test.host'
      expect(response).not_to be_success
      expect(response.status).to eq 500
    end

    it 'successfully responds when the redirec_to parameter is the same host' do
      get :show, redirect_to: 'http://test.host/some-route'
      expect(response).to be_success
      expect(response.status).to eq 200
    end

    it 'assigns the decoded url to the @redirect_to variable' do
      get :show, redirect_to: 'http:%2F%2Ftest.host%2Fsome-route'
      expect(assigns(:redirect_to)).to eq 'http://test.host/some-route'
    end

    it 'handles redirects to non-ascii URLs appropriately' do
      get :show, redirect_to: 'http://test.host/some-route?q=Bedeutung+f%C3%BCr+die+Medi%C3%A4visti'

      expect(response).to be_success
    end
  end
end
