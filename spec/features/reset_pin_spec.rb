# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reset PIN workflow' do
  let(:mock_client) { instance_double(FolioClient, find_patron_by_barcode_or_university_id: patron, ping: true, change_pin: nil) }
  let(:patron) do
    instance_double(
      Folio::Patron,
      email: 'jdoe@stanford.edu',
      display_name: 'J Doe',
      barcode: '123',
      pin_reset_token: 'foo'
    )
  end
  let(:bib_data) { build(:single_holding) }
  let(:request_path) { new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS') }

  before do
    stub_bib_data_json(bib_data)
    allow(FolioClient).to receive(:new).and_return(mock_client)
  end

  describe 'requesting a pin reset' do
    before do
      visit reset_pin_path(referrer: request_path)
      fill_in('university_id', with: '1234567890')
      click_on 'Set/Reset PIN'
    end

    it 'sends a reset email' do
      expect(page).to have_css '.flash_messages', text: 'Success!'
      expect(ResetPinsMailer.deliveries.count).to eq(1)
    end

    it 'redirects to the request page you were on' do
      expect(page).to have_current_path(request_path)
    end

    it 'shows a success message' do
      expect(page).to have_css '.flash_messages', text: 'Success!'
    end
  end

  describe 'changing the pin with a token' do
    context 'when the token is valid' do
      before do
        visit change_pin_with_token_path(token: 'foo', referrer: request_path)
        fill_in('pin', with: 'newpin')
        click_on 'Change PIN'
      end

      it 'redirects to the request page you were on' do
        expect(page).to have_current_path(request_path)
      end

      it 'shows a success message' do
        expect(page).to have_css '.flash_messages', text: 'Success!'
      end

      it 'tells the ILS to change the pin' do
        expect(mock_client).to have_received(:change_pin).with('foo', 'newpin')
      end
    end

    context 'when the token is invalid' do
      before do
        allow(mock_client).to receive(:change_pin).and_raise(ActiveSupport::MessageEncryptor::InvalidMessage)
        visit change_pin_with_token_path(token: 'not_a_real_token')
        fill_in('pin', with: 'newpin')
        click_on 'Change PIN'
      end

      it 'shows the user an error' do
        expect(page).to have_css '.flash_messages', text: 'invalid or expired'
      end
    end

    context 'when asking the ILS to change the PIN fails' do
      before do
        allow(mock_client).to receive(:change_pin).and_raise(FolioClient::IlsError)
        visit change_pin_with_token_path(token: 'foo')
        fill_in('pin', with: 'newpin')
        click_on 'Change PIN'
      end

      it 'shows the user an error' do
        expect(page).to have_css '.flash_messages', text: 'Something went wrong'
      end
    end
  end

  describe 'show/hide password' do
    context 'with javascript', :js do
      before do
        visit change_pin_with_token_path(token: 'foo')
      end

      it 'the input field is a password type' do
        expect(page).to have_css '#pin[type="password"]'
      end

      it 'can be shown by clicking show button' do
        click_on 'Show PIN'
        expect(page).to have_css '#pin[type="text"]'
      end

      it 'can be hidden again after showing' do
        click_on 'Show PIN'
        click_on 'Hide PIN'
        expect(page).to have_css '#pin[type="password"]'
      end
    end

    context 'without javascript' do
      before do
        visit change_pin_with_token_path(token: 'foo')
      end

      it 'the input field is a password type' do
        expect(page).to have_css '#pin[type="password"]'
      end

      it 'hide/show buttons are hidden' do
        expect(page).to have_button 'Show PIN', visible: :hidden
        expect(page).to have_button 'Hide PIN', visible: :hidden
      end
    end
  end
end
