# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Requesting an item from an EAD', :js do
  before do
    allow(Settings.features).to receive(:requests_redesign).and_return(true)
    allow(EadClient).to receive(:fetch).and_return(Ead::Document.new(eadxml, url: 'whatever'))

    login_as(current_user)

    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    allow(aeon_user).to receive_messages(appointments: [
                                           instance_double(Aeon::Appointment,
                                                           start_time: DateTime.new(2026, 2, 19, 12, 0, 0),
                                                           stop_time: DateTime.new(2026, 2, 19, 13, 0, 0),
                                                           id: 1,
                                                           editable?: true,
                                                           sort_key: 1,
                                                           requests: [instance_double(Aeon::Request)],
                                                           reading_room: reading_rooms.last),
                                           instance_double(Aeon::Appointment,
                                                           start_time: DateTime.new(2026, 2, 20, 13, 0, 0),
                                                           stop_time: DateTime.new(2026, 2, 20, 14, 0, 0),
                                                           id: 2,
                                                           editable?: true,
                                                           sort_key: 2,
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
    instance_double(AeonClient, find_user: aeon_user, create_request: created_request, reading_rooms:, available_appointments:)
  end
  let(:created_request) { instance_double(Aeon::Request, id: 123, transaction_number: 'abc123', submitted?: true, draft?: false, valid?: true) }

  let(:available_appointments) do
    [instance_double(Aeon::AvailableAppointment,
                     start_time: DateTime.new(2026, 2, 19),
                     maximum_appointment_length: 210.minutes)]
  end

  context 'with multi item ead' do
    let(:eadxml) do
      Nokogiri::XML(File.read('spec/fixtures/sc0097.xml')).tap(&:remove_namespaces!)
    end

    # rubocop:disable RSpec/ExampleLength
    it 'allows the user to submit a reading room request for an EAD item' do
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

      expect(page).to have_no_css('.selected-items-container .accordion-button')
      expect(page).to have_css('.selected-item-title', text: 'Box 1')

      # In the Appointment step
      click_button 'Select existing appointment'
      click_button 'Feb 19'

      click_button 'Submit request'

      expect(page).to have_css('.confirmation')

      perform_enqueued_jobs
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
      check 'I agree to these terms'
      click_button 'Continue'

      click_link 'Computers and Typesetting'
      click_link 'Legal size documents'
      check 'Box 12'
      click_button 'Continue'

      expect(page).to have_css('.accordion-button[disabled][aria-expanded="true"]', text: 'Box 12')

      # Go back to edit item selection
      within('#items-accordion') do
        click_button 'Edit'
      end

      click_link 'TeX milieu'

      # Now there are 2 selected items
      check 'Box 14'
      click_button 'Continue'

      within('.selected-items-container') do
        expect(page).to have_css('.accordion-button[aria-expanded="true"]', text: 'Box 12')
        expect(page).to have_css('.accordion-button[aria-expanded="false"]', text: 'Box 14')
        expect(page).to have_no_css('.accordion-button[disabled]')
      end

      expect(page).to have_content('Requested pages')
      fill_in 'Requested pages', with: 'Pages 1-10'
      fill_in 'Additional information', with: 'Testing only'

      click_button 'Submit request'

      expect(page).to have_css('.confirmation')

      perform_enqueued_jobs
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
  # rubocop:enable RSpec/ExampleLength

  context 'with ead that has no series' do
    let(:eadxml) do
      Nokogiri::XML(File.read('spec/fixtures/ars0052.xml')).tap(&:remove_namespaces!)
    end

    it 'allows users to input boxes manually' do # rubocop:disable RSpec/ExampleLength
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      expect(page).to have_content('New request')
      expect(page).to have_content('Hilton (Ozzie) Collection')

      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      find('input[data-prepend="manual-input-1"]').set('Box 1')
      click_button 'Add container'
      find('input[data-prepend="manual-input-2"]').set('Box 24 ')
      click_button 'Add container'
      find('input[data-prepend="manual-input-3"]').set('Box 25 ')
      find('button[data-index="2"]').click

      click_button 'Continue'

      expect(page).to have_content('Requested pages')
      expect(page).to have_content('Box 1')
      fill_in 'Requested pages', with: 'Pages 1-10'
      fill_in 'Additional information', with: 'Testing only'
      click_button 'Next item'

      expect(page).to have_content('Box 25')
      fill_in 'Requested pages', with: 'Pages 10-14'
      fill_in 'Additional information', with: 'Testing only'

      click_button 'Submit request'

      expect(page).to have_css('.confirmation')

      perform_enqueued_jobs
      expect(PatronRequest.last.aeon_item.keys).to eq ['manual-input-1-box1', 'manual-input-3-box25']
      expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                        username: user.email_address,
                                                                        item_info5: 'Pages 1-10',
                                                                        item_volume: 'Box 1',
                                                                        special_request: 'Testing only',
                                                                        call_number: 'ARS.0052 ',
                                                                        site: 'ARS'
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

      expect(page).to have_no_css('.selected-items-container .accordion-button')
      expect(page).to have_css('.selected-item-title', text: 'Box 1')

      # In the Appointment step
      expect(page).to have_content('Field Reading Room')
      expect(page).to have_content('Hours: Monday - Friday, 9:00 - 4:45 pm')
      expect(page).to have_content('Appointments must be scheduled at least 5 business days in advance. Maximum of 5 items per day.')

      # In the Appointment step
      click_button 'Select existing appointment'
      click_button 'Feb 19'
    end

    it 'shows expanded item info for digitization request' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')
      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      check 'Box 1'
      click_button 'Continue'

      within('.selected-items-container') do
        expect(page).to have_css('.accordion-button[disabled][aria-expanded="true"]', text: 'Box 1')
      end
    end
  end

  context 'without a logged in user' do
    let(:current_user) { CurrentUser.new({}) }
    let(:eadxml) do
      Nokogiri::XML(File.read('spec/fixtures/a0112.xml')).tap(&:remove_namespaces!)
    end

    it 'shows login page' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      expect(page).to have_content('Pehrson (Elmer Walter) Photograph Album')
      expect(page).to have_content('Log in with SUNet ID')
    end
  end

  context 'when user does not have an email address' do
    let(:user) { create(:library_id_user) }
    let(:eadxml) do
      Nokogiri::XML(File.read('spec/fixtures/a0112.xml')).tap(&:remove_namespaces!)
    end

    before do
      allow(Folio::Patron).to receive(:find_by).with(library_id: user.library_id).and_return(build(:no_email_patron))
    end

    it 'identifies the library of the item' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')
      expect(page).to have_content 'Your library account does not include an email address, which is required to complete this request.'
    end
  end
end
