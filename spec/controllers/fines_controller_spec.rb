# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinesController do
  let(:mock_patron) { instance_double(Folio::Patron, key: '513a9054-5897-11ee-8c99-0242ac120002', fines:, checkouts:) }
  let(:checkouts) { [] }

  let(:fines) do
    [
      instance_double(Folio::Account, key: '1', owed: '12', status: 'BADCHECK', sort_date: Time.zone.now)
    ]
  end

  let(:mock_client) do
    instance_double(
      FolioClient, session_token: '1a2b3c4d5e6f7g8h9i0j', ping: true
    )
  end

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
    allow(controller).to receive_messages(patron_or_group: mock_patron)
  end

  context 'with an unauthenticated request' do
    it 'redirects to the home page' do
      expect(get(:index)).to redirect_to root_url
    end
  end

  context 'with an authenticated request' do
    let(:user) do
      CurrentUser.new(username: 'somesunetid', patron_key: '513a9054-5897-11ee-8c99-0242ac120002', shibboleth: true)
    end

    let(:checkouts) do
      [
        instance_double(Folio::Checkout, key: '2', sort_key: Time.zone.now, accruing?: false, sort_date: Time.zone.now)
      ]
    end

    before do
      allow(mock_patron).to receive_messages(fines:, checkouts:)
      warden.set_user(user)
    end

    it 'redirects to the home page' do
      expect(get(:index)).to render_template 'index'
    end

    it 'assigns a list of fines' do
      get(:index)

      expect(assigns(:fines)).to eq fines
    end

    it 'assigns a list of checkouts' do
      get(:index)

      expect(assigns(:fines_and_accruing)).to eq fines
    end
  end
end
