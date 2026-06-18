# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckoutsController do
  let(:user) { CurrentUser.new(username: 'somesunetid', patron_key: '513a9054-5897-11ee-8c99-0242ac120002', shibboleth: true) }
  let(:mock_patron) { instance_double(Folio::Patron, key: '513a9054-5897-11ee-8c99-0242ac120002', checkouts:) }
  let(:mock_client) { instance_double(FolioClient, ping: true) }
  let(:checkouts) { [] }

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
    allow(controller).to receive(:patron_or_group).and_return(mock_patron)
    warden.set_user(user) if user
  end

  context 'with an unauthenticated request' do
    let(:user) { nil }

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

  describe '#renew' do
    let(:api_response) { instance_double(FolioClient::RenewCheckoutResponse, success?: true, checkout: checkouts[0], updated_checkout: checkouts[0]) }
    let(:checkouts) { [instance_double(Folio::Checkout, item_id: '123', item_category_non_renewable?: false, sort_key: nil)] }

    before do
      allow(mock_client).to receive(:renew_checkout).and_return(api_response)
    end

    context 'when everything is good' do
      it 'renews the item and sets flash messages' do
        post :renew, params: { id: '123' }

        expect(flash[:success]).to include('Success!')
      end

      it 'renews the item and redirects to checkouts_path' do
        post :renew, params: { id: '123' }

        expect(response).to redirect_to checkouts_path
      end
    end

    context 'when the response is not 201' do
      let(:api_response) { instance_double(FolioClient::RenewCheckoutResponse, success?: false, checkout: checkouts[0], updated_checkout: checkouts[0]) }

      it 'does not renew the item and sets flash messages' do
        post :renew, params: { id: '123' }

        expect(flash[:error]).to include('Sorry!')
      end

      it 'does not renew the item and redirects to checkouts_path' do
        post :renew, params: { id: '123' }

        expect(response).to redirect_to checkouts_path
      end
    end

    context 'when the requested item is not checked out to the patron' do
      it 'raises an error' do
        expect { post :renew, params: { id: 'some_made_up_item_id' } }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the requested item is not eligible even though Folio does not stop us' do
      let(:checkouts) { [instance_double(Folio::Checkout, item_id: '123', sort_key: nil, item_category_non_renewable?: true)] }

      it 'does not renew the item and sets flash messages' do
        expect { post :renew, params: { id: '123' } }.to raise_error(CheckoutException)
      end
    end
  end

  describe '#renew_eligible' do
    let(:api_response) { { success: [checkouts[0]], error: [checkouts[1]] } }
    let(:checkouts) do
      [
        instance_double(Folio::Checkout, key: '1', renewable?: true, item_id: '123', title: 'ABC', sort_key: nil),
        instance_double(Folio::Checkout, key: '2', renewable?: true, item_id: '456', sort_key: nil,
                                         title: 'Principles of optics : electromagnetic theory of ' \
                                                'propagation, interference and diffraction of light'),
        instance_double(Folio::Checkout, key: '3', renewable?: false, item_id: '789', sort_key: nil, title: 'Not')
      ]
    end

    before do
      allow(mock_client).to receive(:renew_checkout).with(having_attributes(key: '1')).and_return(instance_double(FolioClient::RenewCheckoutResponse,
                                                                                                                  success?: true,
                                                                                                                  checkout: checkouts[0]))
      allow(mock_client).to receive(:renew_checkout).with(having_attributes(key: '2')).and_return(instance_double(FolioClient::RenewCheckoutResponse,
                                                                                                                  success?: false,
                                                                                                                  checkout: checkouts[1]))
    end

    it 'sends renewal requests to Folio for eligible items' do
      post :renew_eligible

      expect(mock_client).to have_received(:renew_checkout).with(having_attributes(key: '1'))
      expect(mock_client).to have_received(:renew_checkout).with(having_attributes(key: '2'))
    end

    context 'when successful' do
      before { post :renew_eligible }

      it 'sets a success flash message' do
        expect(flash[:success]).to include('Success!')
      end

      it 'includes the number of renewed items' do
        expect(flash[:success]).to include('1 item was renewed')
      end
    end

    describe 'when unsuccessful' do
      before { post :renew_eligible }

      it 'sets an error flash message' do
        expect(flash[:error]).to include('Sorry!')
      end

      it 'includes the truncated titles of errored renewals' do
        expect(Capybara.string(flash[:error])).to have_css('li',
                                                           text: 'Principles of optics : electromagnetic theory of...')
      end
    end

    it 'renews the item and redirects to checkouts_path' do
      post :renew_eligible

      expect(response).to redirect_to checkouts_path
    end
  end
end
