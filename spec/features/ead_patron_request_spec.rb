# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Requesting an item from an EAD', :js do
  before do
    allow(Settings.features).to receive(:requests_redesign).and_return(true)
    allow(EadClient).to receive(:fetch).and_return(Ead::Document.new(eadxml, url: 'whatever'))

    login_as(current_user)

    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    allow(aeon_user).to receive_messages(appointments:,
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

  let(:appointments) do
    [
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
    ]
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

    it 'can search the EAD contents' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      choose 'Reading room appointment'
      click_button 'Continue'

      fill_in 'Search contents', with: 'Japan'
      expect(page).to have_text '1 of 13 matches'
      expect(page).to have_content 'Folder 8: Chinese and Japanese'

      find('[data-ead-search-target="nextButton"]').click
      expect(page).to have_text '2 of 13 matches'
      expect(page).to have_content 'Folder 13: Japanese'

      find('[data-ead-search-target="clearButton"]').click
      expect(page).to have_no_css '[data-ead-search-target="countPill"]'

      fill_in 'Search contents', with: 'box 4'
      expect(page).to have_text '1 of 6 matches'
      expect(page).to have_content 'Box 4'
      expect(page).to have_content 'The Art of Computer Programming'

      find('[data-ead-search-target="prevButton"]').click
      expect(page).to have_text '6 of 6 matches'
      expect(page).to have_content 'Box 4'
      expect(page).to have_content 'Addenda, 2022-104'

      find('[data-ead-search-target="input"]').send_keys(:enter)
      expect(page).to have_text '1 of 6 matches'
      find('[data-ead-search-target="input"]').send_keys(:shift, :enter)
      expect(page).to have_text '6 of 6 matches'
      find('[data-ead-search-target="input"]').send_keys(:escape)
      expect(page).to have_no_css '[data-ead-search-target="countPill"]'
    end

    it 'allows the user to save reading room items for later' do # rubocop:disable RSpec/ExampleLength
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      choose 'Reading room appointment'
      click_button 'Continue'

      click_link 'Computers and Typesetting'
      click_link 'Legal size documents'
      check 'Box 12'
      click_link 'Volume A, The TeXbook'
      check 'Box 13'
      click_button 'Continue'

      # Submit disabled: no items have appointments
      expect(page).to have_button('Submit request', disabled: true)

      # Assign appointment to first item
      within('[data-content-id]', text: 'Box 12') do
        click_button 'Select existing appointment'
        click_button 'Feb 19'
      end
      expect(page).to have_css '.badge', text: '2 items'

      # Submit disabled: second item has no appointment
      expect(page).to have_button('Submit request', disabled: true)

      # Save second item for later
      first('[data-content-id]', text: 'Box 13').click_button('Save for later')
      expect(page).to have_css('.saved-item')

      # Submit enabled: one with appointment, one saved
      expect(page).to have_button('Submit request', disabled: false)

      # Undo restores the item
      click_button 'Undo'
      expect(page).to have_no_css('.saved-item')

      # Save-for-later must not unhide the EAD series tree's `data-toggle-disabled` wrappers.
      expect(page).to have_no_css('.series-contents-container [data-content-id][data-toggle-disabled]:not(.d-none)', visible: :all)

      # Submit disabled: restored item has no appointment
      expect(page).to have_button('Submit request', disabled: true)

      # Assign appointment to the second item
      within('[data-content-id]', text: 'Box 13') do
        click_button 'Select existing appointment'
        click_button 'Feb 19'
      end
      expect(page).to have_css '.badge', text: '3 items'
      expect(page).to have_button('Submit request', disabled: false)

      first('[data-content-id]', text: 'Box 12').click_button('Save for later')

      # Appointment item limit should show that the saved item relinquished the appointment
      expect(page).to have_css '.badge', text: '2 items'

      first('[data-content-id]', text: 'Box 13').click_button('Save for later')
      expect(page).to have_css('.saved-item', count: 2)

      expect(page).to have_button('Submit request', disabled: false)
    end

    it 'preserves saved-for-later items across a request-type round trip' do # rubocop:disable RSpec/ExampleLength
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      choose 'Reading room appointment'
      click_button 'Continue'

      click_link 'Computers and Typesetting'
      click_link 'Legal size documents'
      check 'Box 12'
      click_link 'Volume A, The TeXbook'
      check 'Box 13'
      click_button 'Continue'

      within('[data-content-id]', text: 'Box 12') do
        click_button 'Select existing appointment'
        click_button 'Feb 19'
      end

      # Save Box 13 for later in the reading-room flow
      first('[data-content-id]', text: 'Box 13').click_button('Save for later')
      expect(page).to have_css('.saved-item', text: 'Box 13')

      # Switch request type to digitization
      within('#request-type-accordion') { click_button 'Edit' }
      expect(page).to have_css('#request-type.accordion-collapse.show')
      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'
      expect(page).to have_css('#items-accordion .accordion-collapse.show')
      click_button 'Continue'

      # Saved item is mirrored into the digitization save-for-later list
      expect(page).to have_css('.digitization-accordion')
      expect(page).to have_css('.saved-item', text: 'Box 13')

      # Switch back to reading room; saved item is still there
      within('#request-type-accordion') { click_button 'Edit' }
      expect(page).to have_css('#request-type.accordion-collapse.show')
      choose 'Reading room appointment'
      click_button 'Continue'
      expect(page).to have_css('#items-accordion .accordion-collapse.show')
      click_button 'Continue'
      expect(page).to have_css('.saved-item', text: 'Box 13')

      # Submit is enabled because Box 12 has an appointment and Box 13 is saved
      expect(page).to have_button('Submit request', disabled: false)
    end

    it 'shows the request-type Edit button when save-for-later is triggered from the digitization flow' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      click_link 'Computers and Typesetting'
      click_link 'Legal size documents'
      check 'Box 12'
      click_link 'Volume A, The TeXbook'
      check 'Box 13'
      click_button 'Continue'

      first('[data-content-id]', text: 'Box 13').click_button('Save for later')
      expect(page).to have_css('.saved-item', text: 'Box 13')

      # The Edit button on request-type must still be clickable. A regression test
      # for a `stretched-link` class that was being cloned from the form item's
      # title span into the saved-item clone, where its ::after overlay ended up
      # covering the entire page because the saved clone had no positioned
      # ancestor to constrain it.
      within('#request-type-accordion') { click_button 'Edit' }
      expect(page).to have_css('#request-type.accordion-collapse.show')
    end

    it 'keeps Submit enabled after editing request type with items saved for later' do # rubocop:disable RSpec/ExampleLength
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      choose 'Reading room appointment'
      click_button 'Continue'

      click_link 'Computers and Typesetting'
      click_link 'Legal size documents'
      check 'Box 12'
      click_link 'Volume A, The TeXbook'
      check 'Box 13'
      click_button 'Continue'

      within('[data-content-id]', text: 'Box 12') do
        click_button 'Select existing appointment'
        click_button 'Feb 19'
      end
      first('[data-content-id]', text: 'Box 13').click_button('Save for later')

      expect(page).to have_button('Submit request', disabled: false)

      # Click Edit on request type, then Continue without changing anything
      within('#request-type-accordion') { click_button 'Edit' }
      expect(page).to have_css('#request-type.accordion-collapse.show')
      click_button 'Continue'
      expect(page).to have_css('#items-accordion .accordion-collapse.show')
      click_button 'Continue'
      expect(page).to have_css('#reading.accordion-collapse.show')

      expect(page).to have_button('Submit request', disabled: false)
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

      click_button 'Next item'
      fill_in 'Requested pages', with: 'Pages 6-8'

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
      expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                        username: user.email_address,
                                                                        item_info5: 'Pages 6-8',
                                                                        item_volume: 'Box 14',
                                                                        call_number: 'SC0097 Computers and Typesetting',
                                                                        site: 'SPECUA'
                                                                      ))
    end

    it 'displays a modal to view contents of each selected item for reading room appointments' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      choose 'Reading room appointment'
      click_button 'Continue'

      click_link 'Computers and Typesetting'
      click_link 'Volume E, Computer Modern Typefaces'
      check 'Box 22'
      check 'Box 23'

      click_button 'Continue'

      # Expect links for viewing a modal for each of the selecte boxes
      expect(page).to have_css('button[data-action="view-container-contents#openViewModal"]', count:2)

      # Clicking on the view modal link should display the contents of the first container
      page.find('button[data-item-id="volumes_computers-and-typesetting_volume-e-computer-modern-t_box-22"]').click
      within '.modal' do
        # Skipping the HTML > elements when looking at just the text
        expect(page).to have_content('Computers and TypesettingVolume E, Computer Modern TypefacesBox 22')
        expect(page).to have_content 'Folder 1: What preceded Computer Modern'
        # There are 9 folders in this box
        expect(page).to have_css('li', count:9)
        page.find('button.btn-close').click
      end
      
      # Clicking the second container view modal link should show us 11 items
      page.find('button[data-item-id="volumes_computers-and-typesetting_volume-e-computer-modern-t_box-23"]').click
      within '.modal' do
        expect(page).to have_content('Computers and TypesettingVolume E, Computer Modern TypefacesBox 23')
        expect(page).to have_css('li', count:11)
        page.find('button.btn-close').click
      end
    end

    it 'displays a modal to view contents of each selected item for a digitization request' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      click_link 'Concrete Mathematics'
      click_link 'Original Drafts'
      check 'Box 26'
      check 'Box 27'

      click_button 'Continue'

      # Expect links for viewing a modal for each of the selected boxes
      expect(page).to have_css('button[data-action="view-container-contents#openViewModal"]', count:2)

      # Clicking on the view modal link should display the contents of the first container
      page.find('button[data-item-id="volumes_concrete-mathematics_original-drafts_box-26"]').click
      within '.modal' do
        # There are 6 folders in this box
        expect(page).to have_css('li', count:6)
        page.find('button.btn-close').click
      end
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

      # In the Appointment step
      click_button 'Select existing appointment'
      click_button 'Feb 19'
    end

    context 'when there are no appointments' do
      let(:appointments) { [] }

      it 'shows appointment alert' do
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
        expect(page).to have_content('You don’t have any appointments yet. Create one to continue.')
        expect(page).to have_button('Select existing appointment', disabled: true)
      end
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

  context 'with invalid or missing EAD XML' do
    let(:eadxml) { Nokogiri::XML('<ead/>') } # valid enough for Ead::Document.new, won't actually be used

    before do
      allow(EadClient).to receive(:fetch).and_raise(EadClient::InvalidDocument)
    end

    it 'shows an invalid document error' do
      visit new_archives_request_path(value: 'http://example.com/not-an-ead.xml')

      expect(page).to have_content('Missing or invalid EAD XML')
      expect(page).to have_content('Please check your finding aid source')
    end

    context 'when a network error occurs instead' do
      before do
        allow(EadClient).to receive(:fetch).and_raise(EadClient::Error)
      end

      it 'shows a generic error' do
        visit new_archives_request_path(value: 'http://example.com/ead.xml')

        expect(page).to have_content('Error Loading Collection Information')
        expect(page).to have_content('Please try again later')
      end
    end
  end
end
