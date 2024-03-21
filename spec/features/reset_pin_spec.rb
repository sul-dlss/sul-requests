# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reset PIN workflow' do
  let(:mock_client) { instance_double(FolioClient, find_patron_by_barcode: patron, ping: true, change_pin: nil) }
  let(:patron) do
    instance_double(
      Folio::Patron,
      email: 'jdoe@stanford.edu',
      display_name: 'J Doe',
      barcode: '123',
      pin_reset_token: 'foo'
    )
  end

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
  end

  context 'when logged in' do
    before do
      login_as(username: 'stub_user', patron_key: '50e8400-e29b-41d4-a716-446655440000')
    end

    it 'logs out user and redirects to root' do
      visit reset_pin_path
      expect(page).to have_css 'h1', text: 'Log in to see your checkouts, requests, fines & fees'
    end
  end

  it 'allows user to reset pin' do
    visit reset_pin_path
    fill_in('library_id', with: '123456')
    click_on 'Reset/Request PIN'
    expect(page).to have_css '.flash_messages', text: 'Check your email!'
  end

  it 'a user can change their pin' do
    visit change_pin_with_token_path(token: 'foo')
    fill_in('pin', with: '123456')
    click_on 'Change PIN'
    expect(page).to have_css '.flash_messages', text: 'Success!'
  end

  context 'when the token is invalid' do
    before do
      allow(mock_client).to receive(:change_pin).and_raise(ActiveSupport::MessageEncryptor::InvalidMessage)
    end

    it 'shows the user an error' do
      visit change_pin_with_token_path(token: 'not_a_real_token')
      fill_in('pin', with: 'newpin')
      click_on 'Change PIN'
      expect(page).to have_css '.flash_messages', text: 'invalid or expired'
    end
  end

  context 'when asking the ILS to change the PIN fails' do
    before do
      allow(mock_client).to receive(:change_pin).and_raise(FolioClient::IlsError)
    end

    it 'shows the user an error' do
      visit change_pin_with_token_path(token: 'foo')
      fill_in('pin', with: 'newpin')
      click_on 'Change PIN'
      expect(page).to have_css '.flash_messages', text: 'Something went wrong'
    end
  end

  describe 'show/hide password', :js do
    it 'by default the field is a password type' do
      visit change_pin_with_token_path(token: 'foo')
      expect(page).to have_css '[type="password"]'
    end

    it 'can be shown by clicking show/hide button' do
      visit change_pin_with_token_path(token: 'foo')
      within '#main form' do
        first('[data-visibility]').click
        expect(page).to have_css '[type="text"]'
      end
    end
  end
end
