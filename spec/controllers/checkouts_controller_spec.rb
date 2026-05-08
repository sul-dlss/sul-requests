# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckoutsController do
  let(:mock_patron) { instance_double(Folio::Patron) }
  let(:mock_client) { instance_double(FolioClient, ping: true) }

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
    allow(controller).to receive(:patron_or_group).and_return(mock_patron)
  end

  context 'with an unauthenticated request' do
    it 'redirects to the home page' do
      expect(get(:index)).to redirect_to root_url
    end
  end

  context 'with an authenticated request' do
    let(:user) do
      build(:sso_user)
    end

    let(:checkouts) do
      [
        instance_double(Folio::Checkout, key: '1', sort_key: nil)
      ]
    end

    before do
      allow(mock_patron).to receive(:checkouts).and_return(checkouts)
      stub_current_user(user)
    end

    it 'displays list of checkouts' do
      expect(get(:index)).to render_template 'index'
    end

    it 'assigns a list of checkouts' do
      get(:index)

      expect(assigns(:checkouts)).to eq checkouts
    end
  end
end
