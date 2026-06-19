# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IllRequestsController do
  let(:mock_patron) { instance_double(Folio::Patron, borrow_direct_requests:, illiad_requests: [], key: '513a9054-5897-11ee-8c99-0242ac120002') }
  let(:borrow_direct_requests) do
    [
      instance_double(Folio::Request, key: '1', sort_key: nil),
      instance_double(BorrowDirectReshareRequests::ReshareRequest, key: 'sta-1', sort_key: nil)
    ]
  end

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
      CurrentUser.new(username: 'somesunetid', patron_key: '513a9054-5897-11ee-8c99-0242ac120002', shibboleth: true)
    end

    before do
      warden.set_user(user)
    end

    it 'assigns requests' do
      get(:index)

      expect(assigns(:requests).length).to eq 2
    end
  end
end
