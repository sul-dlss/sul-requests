# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Requesting an item from an EAD', :js do
  before do
    allow(EadClient).to receive(:fetch).and_return(Ead::Document.new(eadxml, url: 'whatever'))

    login_as(current_user)

    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    allow(aeon_user).to receive_messages(appointments: [
                                           instance_double(Aeon::Appointment,
                                                           start_time: DateTime.new(2026, 2, 19, 12, 0, 0),
                                                           stop_time: DateTime.new(2026, 2, 19, 13, 0, 0),
                                                           id: 1,
                                                           requests: [instance_double(Aeon::Request)],
                                                           reading_room: reading_rooms.last),
                                           instance_double(Aeon::Appointment,
                                                           start_time: DateTime.new(2026, 2, 20, 13, 0, 0),
                                                           stop_time: DateTime.new(2026, 2, 20, 14, 0, 0),
                                                           id: 1,
                                                           requests: [instance_double(Aeon::Request)],
                                                           reading_room: reading_rooms.first)
                                         ],
                                         requests: [])
  end

  let(:reading_rooms) { JSON.load_file('spec/fixtures/reading_rooms.json').map { |room| Aeon::ReadingRoom.from_dynamic(room) } }

  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true, ldap_attributes: {}) }

  let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }

  let(:stub_aeon_client) do
    instance_double(AeonClient, find_user: aeon_user, create_request: { success: true }, reading_rooms:, available_appointments:)
  end

  let(:available_appointments) do
    [instance_double(Aeon::AvailableAppointment,
                     start_time: DateTime.new(2026, 2, 19),
                     maximum_appointment_length: 210.minutes)]
  end

  context 'with multi item ead' do
    let(:eadxml) do
      Nokogiri::XML(File.read('spec/fixtures/sc0097.xml')).tap(&:remove_namespaces!)
    end

    it 'allows the user to submit a request for an EAD item' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      expect(page).to have_content('New request')
      expect(page).to have_content('Knuth (Donald E.) papers')

      choose 'Reading room appointment'

      expect(page).to have_content('Earliest appointment available: Thursday, Feb 19, 2026')

      click_button 'Continue'

      click_link 'Computers and Typesetting'
      click_link 'Legal size documents'

      check 'Box 12'
      click_button 'Continue'

      # In the Appointment step
      select 'Feb 19', from: 'Select an appointment'

      # Input isn't triggered by Capbayara, this works fine with a user/keyboard interaction
      # this allows the continue button to be enabled.
      page.execute_script("document.querySelector('select').dispatchEvent(new Event('input', { bubbles: true }))")
      click_button 'Submit to Aeon'

      expect(page).to have_content('We received your reading room access request')
      expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                        username: user.email_address,
                                                                        call_number: 'SC0097 Computers and Typesetting',
                                                                        item_volume: 'Box 12',
                                                                        site: 'SPECUA'
                                                                      ))
    end

    it 'allows the user to submit a request with details about the portion of the item to be digitized' do # rubocop:disable RSpec/ExampleLength
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      expect(page).to have_content('New request')
      expect(page).to have_content('Knuth (Donald E.) papers')

      choose 'Digitization'

      click_button 'Continue'

      click_link 'Computers and Typesetting'
      click_link 'Legal size documents'
      check 'Box 12'
      click_button 'Continue'

      expect(page).to have_content('Requested pages')
      fill_in 'Requested pages', with: 'Pages 1-10'
      fill_in 'Additional information', with: 'Testing only'
      click_button 'Continue'

      check 'I agree to these terms'
      click_button 'Submit to Aeon'

      expect(page).to have_content('We received your digitization request')
      expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                        username: user.email_address,
                                                                        item_info5: 'Pages 1-10',
                                                                        item_volume: 'Box 12',
                                                                        special_request: 'Testing only',
                                                                        call_number: 'SC0097 Computers and Typesetting',
                                                                        site: 'SPECUA'
                                                                      ))
    end
  end

  context 'with single item ead' do
    let(:eadxml) do
      Nokogiri::XML(File.read('spec/fixtures/a0112.xml')).tap(&:remove_namespaces!)
    end

    it 'shows list of users relevant appointments' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      expect(page).to have_content('New request')
      expect(page).to have_content('Pehrson (Elmer Walter) Photograph Album')

      choose 'Reading room appointment'

      expect(page).to have_content('Earliest appointment available: Thursday, Feb 19, 2026')

      click_button 'Continue'

      check 'Box 1'
      click_button 'Continue'

      # In the Appointment step
      expect(page).to have_content('Field Reading Room')
      expect(page).to have_content('Hours: Monday - Friday, 9:00 - 4:45 PM')
      expect(page).to have_content('Appointments must be scheduled at least 5 business days in advance. Maximum of 5 items per day.')
      expect(find('select[name="appointment"]').all('option').map(&:text)).to eq ['', 'Feb 19, 2026 ● 12:00 PM - 1:00 PM (1 item)']
    end
  end
end
