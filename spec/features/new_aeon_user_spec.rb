# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating new accounts for patrons', :js do
  use_stub_aeon_client

  before do
    allow(Settings.features).to receive_messages(requests_redesign: true, authenticate_name_email_users: true)
    allow(EadClient).to receive(:fetch).and_return(Ead::Document.new(eadxml, url: 'whatever'))
  end

  let(:eadxml) do
    Nokogiri::XML(File.read('spec/fixtures/sc0097.xml')).tap(&:remove_namespaces!)
  end

  context 'with an SSO user' do
    let(:user) { create(:sso_user) }
    let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true, ldap_attributes: {}) }

    let(:patron) { build(:patron) }

    before do
      allow(Folio::Patron).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
      login_as(current_user)
    end

    it 'renders the Aeon terms and conditions' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      expect(page).to have_text('Terms')
      check('I agree to these terms')

      click_button 'Continue'

      expect(page).to have_text('New request')
    end
  end

  context 'with a name/email user' do
    let(:user) { nil }
    let(:current_user) { nil }

    it 'makes the user provide all the information needed to create an Aeon user' do # rubocop:disable RSpec/ExampleLength
      allow(SendOtpJob).to receive(:perform_later)
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      find('summary', text: 'Proceed as visitor').click
      fill_in 'Name', with: 'Test User'
      fill_in 'Email', with: 'test@localhost'

      click_button 'Continue'

      expect(page).to have_text('Verify email address')
      expect(SendOtpJob).to have_received(:perform_later).with('test@localhost')
      6.times do |i|
        fill_in "Digit #{i + 1}", with: '0'
      end
      click_button 'Continue'

      expect(page).to have_text('Account information')
      expect(page).to have_field('Name', with: 'Test User')
      expect(page).to have_field('Email address', with: 'test@localhost')
      fill_in 'Phone', with: '1234552'
      fill_in 'Address', with: '560 Escondido Mall'
      fill_in 'City', with: 'Stanford'
      fill_in 'State or province', with: 'CA'
      fill_in 'Zip code', with: '94305'
      fill_in 'Country', with: 'USA'

      click_button 'Continue'
      check('I agree to these terms')

      expect do
        click_button 'Submit'
      end.to change(StubAeonClient::User, :count).by(1)

      expect(StubAeonClient::User.last).to have_attributes(
        username: 'test@localhost',
        cleared: 'No',
        firstName: 'Test User',
        address: '560 Escondido Mall',
        city: 'Stanford',
        state: 'CA',
        country: 'USA',
        zip: '94305',
        phone: '1234552'
      )
    end
  end
end
