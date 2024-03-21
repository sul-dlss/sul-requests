# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reset PIN requests' do
  let(:mock_client) { instance_double(FolioClient, find_patron_by_barcode: patron, ping: true) }
  let(:patron) do
    instance_double(
      Folio::Patron,
      display_name: 'Patron',
      barcode: 'PATRON',
      email: 'patron@example.com',
      pin_reset_token: 'abcdef'
    )
  end

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
  end

  context 'when the user is already authenticated via sunetid' do
    let(:user) do
      { username: 'somesunetid', patron_key: '513a9054-5897-11ee-8c99-0242ac120002' }
    end

    before do
      stub_current_user(user)
    end

    describe 'visiting the reset page' do
      it 'logs you out first' do
        get reset_pin_path
        expect(response).to redirect_to logout_path
      end
    end

    describe 'requesting a reset' do
      it 'logs you out first' do
        post reset_pin_path
        expect(response).to redirect_to logout_path
      end
    end
  end

  describe 'requesting a reset' do
    before do
      post reset_pin_path, params: { library_id: '123456' }
    end

    it 'sends the user an email' do
      expect(ResetPinsMailer.deliveries.count).to eq(1)
    end

    it 'shows a success message' do
      expect(flash[:success]).to match(/associated with library ID 123456/)
    end
  end

  describe 'changing the PIN' do
    it 'requires a token and a new pin' do
      expect { post change_pin_path }.to raise_error(ActionController::ParameterMissing)
    end

    context 'when the ILS successfully changes the PIN' do
      let(:mock_client) { instance_double(FolioClient, change_pin: {}, ping: true) }

      before do
        post change_pin_path, params: { token: 'abc', pin: '1234' }
      end

      it 'shows a success message' do
        expect(flash[:success]).to match(/Success!/)
      end

      it 'redirects to the login page' do
        expect(response).to redirect_to login_path
      end
    end

    context 'when the ILS fails to change the PIN' do
      before do
        allow(mock_client).to receive(:change_pin).and_raise(FolioClient::IlsError)
        post change_pin_path, params: { token: 'abc', pin: '1234' }
      end

      it 'shows an error message' do
        expect(flash[:error]).to match(/Sorry!/)
      end

      it 'redirects to the reset PIN page' do
        expect(response).to redirect_to reset_pin_path
      end
    end
  end
end
