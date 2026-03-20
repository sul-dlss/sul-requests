# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating new accounts for patrons', :js do
  before do
    allow(Settings.features).to receive_messages(requests_redesign: true, authenticate_name_email_users: true)
    allow(EadClient).to receive(:fetch).and_return(Ead::Document.new(eadxml, url: 'whatever'))

    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)

    allow(stub_aeon_client).to receive(:find_user).ordered.and_return(
      null_aeon_user,
      aeon_user
    )
  end

  let(:null_aeon_user) { Aeon::NullUser.new }
  let(:aeon_user) { Aeon::User.new(username: user&.email_address, auth_type: 'Default') }

  let(:stub_aeon_client) do
    instance_double(AeonClient, find_user: Aeon::NullUser.new, create_user: nil, reading_rooms: reading_rooms, appointments_for: [],
                                available_appointments: [])
  end

  let(:reading_rooms) { JSON.load_file('spec/fixtures/reading_rooms.json').map { |room| Aeon::ReadingRoom.from_dynamic(room) } }

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

      expect(page).to have_content('Terms')
      check('I agree to these terms')

      click_button 'Continue'

      expect(page).to have_content('New request')

      expect(stub_aeon_client).to have_received(:create_user).with({
                                                                     user_data: an_object_having_attributes(
                                                                       sso: true,
                                                                       email_address: user.email_address,
                                                                       first_name: 'Test', last_name: 'User'
                                                                     )
                                                                   })
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

      expect(page).to have_content('Verify email address')
      expect(SendOtpJob).to have_received(:perform_later).with('test@localhost')
      6.times do |i|
        fill_in "Digit #{i + 1}", with: '0'
      end
      click_button 'Continue'

      expect(page).to have_content('Account information')
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

      click_button 'Submit'

      expect(stub_aeon_client).to have_received(:create_user).with({
                                                                     user_data: AeonClient::UserData.with_defaults.with(
                                                                       address: '560 Escondido Mall',
                                                                       address2: '',
                                                                       city: 'Stanford',
                                                                       country: 'USA',
                                                                       phone: '1234552',
                                                                       zip_code: '94305',
                                                                       email_address: 'test@localhost',
                                                                       first_name: 'Test User',
                                                                       state_or_province: 'CA'
                                                                     )
                                                                   })
    end
  end
end
