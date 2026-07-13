# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FolioRequestsController do
  let(:mock_patron) { instance_double(Folio::Patron, requests:, key: '513a9054-5897-11ee-8c99-0242ac120002') }
  let(:requests) { [] }

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

    let(:requests) do
      [
        instance_double(Folio::Request, key: '1', sort_key: nil)
      ]
    end

    let(:mock_client) { instance_double(FolioClient, ping: true) }

    before do
      allow(FolioClient).to receive(:new).and_return(mock_client)
      warden.set_user(user)
    end

    it 'redirects to the home page' do
      expect(get(:index)).to render_template 'index'
    end

    it 'assigns a list of requests' do
      get(:index)
      expect(assigns(:requests)).to eq requests
    end

    describe '#update' do
      let(:api_response) { instance_double(Faraday::Response, status: 204) }

      let(:requests) do
        [instance_double(Folio::Request, key: '123', sort_key: nil)]
      end

      let(:mock_client) { instance_double(FolioClient, ping: true) }

      before do
        allow(FolioClient).to receive(:new).and_return(mock_client)
      end

      context 'when service_point param is sent' do
        let(:mock_client) { instance_double(FolioClient, change_pickup_service_point: api_response, ping: true) }

        it 'updates the pickup library and sets the flash message' do
          patch :update, params: { id: '123', service_point: 'Other library' }

          expect(flash[:success].first).to match(/Success!.*pickup location was updated/)
        end
      end

      context 'when not_needed_after param is sent' do
        let(:mock_client) { instance_double(FolioClient, change_pickup_expiration: api_response, ping: true) }

        it 'updates the not needed after and sets the flash message' do
          patch :update, params: { id: '123', not_needed_after: '1999/01/01' }

          expect(flash[:success].first).to match(/Success!.*not needed after date was updated/)
        end

        it 'does not update the not needed after if dates are not changed' do
          patch :update, params: {
            id: '123', not_needed_after: '1999/01/01', current_fill_by_date: '1999/01/01'
          }

          expect(flash[:success]).to eq []
        end
      end

      context "when the request key does not match any of the patron's requests" do
        it 'does not renew the item and sets flash messages' do
          patch :update, params: { id: 'some_other_request_key' }

          expect(flash[:error]).to match('An unexpected error has occurred')
        end

        it 'does not renew the item and redirects to folio_requests_path' do
          patch :update, params: { id: 'some_other_request_key' }

          expect(response).to redirect_to unified_requests_path
        end
      end
    end

    describe '#destroy' do
      let(:api_response) { instance_double(Faraday::Response, status: 204) }
      let(:mock_client) { instance_double(FolioClient, cancel_request: api_response, ping: true) }

      let(:requests) do
        [instance_double(Folio::Request, key: '123', sort_key: nil)]
      end

      before do
        allow(FolioClient).to receive(:new).and_return(mock_client)
      end

      context 'when everything is good' do
        it 'cancels the hold and sets flash messages' do
          delete :destroy, params: { id: '123' }
          expect(flash[:success]).to include('Success!')
        end

        it 'cancels the hold and redirects to folio_requests_path' do
          delete :destroy, params: { id: '123' }
          expect(response).to redirect_to unified_requests_path
        end
      end

      context 'when the response is not 204' do
        let(:api_response) { instance_double(Faraday::Response, status: 401, body: 'foo') }

        it 'does not cancel the hold and sets flash messages' do
          delete :destroy, params: { id: '123' }
          expect(flash[:error]).to include('Sorry!')
        end

        it 'does not cancel the hold and redirects to folio_requests_path' do
          delete :destroy, params: { id: '123' }
          expect(response).to redirect_to unified_requests_path
        end
      end
    end

    context "when the request key does not match any of the patron's requests" do
      it 'does not renew the item and sets flash messages' do
        delete :destroy, params: { id: 'some_other_request_key' }

        expect(flash[:error]).to match('An unexpected error has occurred')
      end

      it 'does not renew the item and redirects to folio_requests_path' do
        delete :destroy, params: { id: 'some_other_request_key' }

        expect(response).to redirect_to unified_requests_path
      end
    end
  end
end
