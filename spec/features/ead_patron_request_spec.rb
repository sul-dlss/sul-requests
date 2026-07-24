# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Requesting an item from an EAD', :js do
  use_stub_aeon_client

  before do
    allow(Settings.features).to receive(:requests_redesign).and_return(true)
    allow(EadClient).to receive(:fetch).and_return(Ead::Document.new(eadxml, url: 'whatever'))
    create(:remote_aeon_activity, users: [{ username: aeon_user.username }])

    appointments

    login_as(current_user)
  end

  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true, ldap_attributes: {}) }

  let(:aeon_user) { StubAeonClient::User.create(username: user.email_address, authType: 'Default') }

  let(:reading_room_spec) { StubAeonClient::ReadingRoom.find_by(name: 'Field Reading Room') }
  let(:reading_room_rumsey) { StubAeonClient::ReadingRoom.find_by(name: 'Rumsey Reading Room') }

  let(:appointment_start_time) { 1.week.from_now }
  let(:appointments) do
    [
      create(:remote_aeon_appointment, username: user.email_address, reading_room: reading_room_spec, startTime: appointment_start_time,
                                       stopTime: appointment_start_time + 1.hour),

      create(:remote_aeon_appointment, username: user.email_address, reading_room: reading_room_rumsey, startTime: 2.weeks.from_now,
                                       stopTime: 2.weeks.from_now + 2.hours)
    ]
  end

  context 'with multi item ead' do
    let(:eadxml) do
      Nokogiri::XML(File.read('spec/fixtures/sc0097.xml')).tap(&:remove_namespaces!)
    end

    # rubocop:disable RSpec/ExampleLength
    it 'allows the user to submit a reading room request for an EAD item' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      expect(page).to have_text('New request')
      expect(page).to have_text('Knuth (Donald E.) papers')

      choose 'Reading room appointment'

      expect(page).to have_text('Earliest appointment available:')

      click_button 'Continue'

      click_link 'Computers and Typesetting'
      click_link 'Legal size documents'

      check 'Box 12'
      click_button 'Continue'

      expect(page).to have_no_css('.selected-items-container .accordion-button')
      expect(page).to have_css('.selected-item-title', text: 'Box 1')

      # In the Appointment step
      click_button 'Select appointment'
      click_button appointment_start_time.strftime('%b %-d')

      click_button 'Submit request'

      expect(page).to have_css('.confirmation')

      expect do
        perform_enqueued_jobs
      end.to change(StubAeonClient::Request, :count).by(1)

      expect(StubAeonClient::Request.last).to have_attributes(
        callNumber: 'SC0097 Computers and Typesetting',
        itemVolume: 'Box 12',
        username: user.email_address,
        site: 'SPECUA'
      )
    end

    it 'can search the EAD contents' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      choose 'Reading room appointment'
      click_button 'Continue'

      fill_in 'Search contents', with: 'Japan'
      expect(page).to have_text '1 of 13 matches'
      expect(page).to have_text 'Folder 8: Chinese and Japanese'

      find('[data-ead-search-target="nextButton"]').click
      expect(page).to have_text '2 of 13 matches'
      expect(page).to have_text 'Folder 13: Japanese'

      find('[data-ead-search-target="clearButton"]').click
      expect(page).to have_no_css '[data-ead-search-target="countPill"]'

      fill_in 'Search contents', with: 'box 4'
      expect(page).to have_text '1 of 6 matches'
      expect(page).to have_text 'Box 4'
      expect(page).to have_text 'The Art of Computer Programming'

      find('[data-ead-search-target="prevButton"]').click
      expect(page).to have_text '6 of 6 matches'
      expect(page).to have_text 'Box 4'
      expect(page).to have_text 'Addenda, 2022-104'

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
        click_button 'Select appointment'
        click_button appointment_start_time.strftime('%b %-d')
      end
      expect(page).to have_css '.badge', text: '1 item'

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
        click_button 'Select appointment'
        click_button appointment_start_time.strftime('%b %-d')
      end
      expect(page).to have_css '.badge', text: '2 items'
      expect(page).to have_button('Submit request', disabled: false)

      first('[data-content-id]', text: 'Box 12').click_button('Save for later')

      # Appointment item limit should show that the saved item relinquished the appointment
      expect(page).to have_css '.badge', text: '1 item'

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
        click_button 'Select appointment'
        click_button appointment_start_time.strftime('%b %-d')
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
        click_button 'Select appointment'
        click_button appointment_start_time.strftime('%b %-d')
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

    it 'allows the user to submit a request with activites selected' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      expect(page).to have_text('New request')
      expect(page).to have_text('Knuth (Donald E.) papers')

      choose 'Activity'
      click_button 'Continue'

      click_link 'Computers and Typesetting'
      click_link 'Legal size documents'
      check 'Box 12'
      click_button 'Continue'

      check 'activity-1'

      click_button 'Submit request'

      expect(page).to have_css('.confirmation')

      expect do
        perform_enqueued_jobs
      end.to change(StubAeonClient::Request, :count).by(1)

      expect(StubAeonClient::Request.last).to have_attributes(
        requestFor: { type: 'Activity', reference: '1' },
        callNumber: 'SC0097 Computers and Typesetting',
        username: user.email_address
      )
    end

    it 'allows the user to submit a request with details about the portion of the item to be digitized' do # rubocop:disable RSpec/ExampleLength
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      expect(page).to have_text('New request')
      expect(page).to have_text('Knuth (Donald E.) papers')

      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      click_link 'Computers and Typesetting'
      click_link 'Legal size documents'
      check 'Box 12'
      click_button 'Continue'

      within('.selected-items-container .accordion-item', text: 'Box 12') do
        expect(page).to have_css('.accordion-button[disabled][aria-expanded="true"]')
      end

      # Go back to edit item selection
      within('#items-accordion') do
        click_button 'Edit'
      end

      click_link 'TeX milieu'

      # Now there are 2 selected items
      check 'Box 14'
      click_button 'Continue'

      within('.selected-items-container') do
        within('.accordion-item', text: 'Box 12') do
          expect(page).to have_css('.accordion-button[aria-expanded="true"]')
        end
        within('.accordion-item', text: 'Box 14') do
          expect(page).to have_css('.accordion-button[aria-expanded="false"]')
        end
        expect(page).to have_no_css('.accordion-button[disabled]')
      end

      expect(page).to have_text('Requested pages')
      fill_in 'Requested pages', with: 'Pages 1-10'
      fill_in 'Additional information', with: 'Testing only'

      click_button 'Next item'
      fill_in 'Requested pages', with: 'Pages 6-8'

      click_button 'Submit request'

      expect(page).to have_css('.confirmation')

      expect do
        perform_enqueued_jobs
      end.to change(StubAeonClient::Request, :count).by(2)

      expect(StubAeonClient::Request.last(2)).to contain_exactly(
        have_attributes(
          callNumber: 'SC0097 Computers and Typesetting',
          itemVolume: 'Box 12',
          itemInfo5: 'Pages 1-10',
          specialRequest: 'Testing only',
          username: user.email_address,
          site: 'SPECUA'
        ),
        have_attributes(
          callNumber: 'SC0097 Computers and Typesetting',
          itemVolume: 'Box 14',
          itemInfo5: 'Pages 6-8',
          username: user.email_address,
          site: 'SPECUA'
        )
      )
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
      expect(page).to have_css('button[data-action="view-container-contents#openViewModal"]', count: 2)

      # Clicking on the view modal link should display the contents of the first container
      page.find('button[data-item-id="volumes_computers-and-typesetting_volume-e-computer-modern-t_box-22"]').click
      within '.modal' do
        # Skipping the HTML > elements when looking at just the text
        expect(page).to have_text('Computers and TypesettingVolume E, Computer Modern TypefacesBox 22')
        expect(page).to have_text 'Folder 1: What preceded Computer Modern'
        # There are 9 folders in this box
        expect(page).to have_css('li', count: 9)
        click_button(class: 'btn-close')
      end

      # Clicking the second container view modal link should show us 11 items
      page.find('button[data-item-id="volumes_computers-and-typesetting_volume-e-computer-modern-t_box-23"]').click
      within '.modal' do
        expect(page).to have_text('Computers and TypesettingVolume E, Computer Modern TypefacesBox 23')
        expect(page).to have_css('li', count: 11)
        click_button(class: 'btn-close')
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
      expect(page).to have_css('button[data-action="view-container-contents#openViewModal"]', count: 2)

      # Clicking on the view modal link should display the contents of the first container
      page.find('button[data-item-id="volumes_concrete-mathematics_original-drafts_box-26"]').click
      within '.modal' do
        # There are 6 folders in this box
        expect(page).to have_css('li', count: 6)
        click_button(class: 'btn-close')
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength

  context 'with ead that has no series' do
    let(:eadxml) do
      Nokogiri::XML(File.read('spec/fixtures/ars0052.xml')).tap(&:remove_namespaces!)
    end

    it 'does not show activity radio button, due to activity being associated with SPECUA' do
      expect(page).to have_no_checked_field('Activity')
    end

    it 'preserves saved-for-later manually added items' do # rubocop:disable RSpec/ExampleLength
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      first('[data-manual-items-row] input[type=text]').set('Box 1')
      click_button 'Add container'
      all('[data-manual-items-row] input[type=text]')[1].set('Box 2')
      click_button 'Continue'

      # Row title edits round-trip through the accordion summary
      within('#items-accordion') { click_button 'Edit' }
      first('[data-manual-items-row] input[type=text]').set('Renamed')
      click_button 'Continue'
      expect(page).to have_text 'Renamed'
      expect(page).to have_no_text 'Box 1'

      within('#items-accordion') { click_button 'Edit' }
      first('[data-manual-items-row] input[type=text]').set('Box 1')
      click_button 'Continue'

      first('[data-content-id]', text: 'Box 1').click_button('Save for later')
      first('[data-content-id]', text: 'Box 2').click_button('Save for later')
      expect(page).to have_css('.saved-item', text: 'Box 1')
      expect(page).to have_css('.saved-item', text: 'Box 2')

      within('#items-accordion') { click_button 'Edit' }

      # Saved for later manual items are hidden but still in the DOM so they submit
      expect(page).to have_css('[data-manual-items-row].d-none', count: 2, visible: :hidden)
      expect(page).to have_no_field(with: 'Box 1')
      expect(page).to have_no_field(with: 'Box 2')

      # Add a new, not saved for later manual item
      click_button 'Add container'
      first('[data-manual-items-row]:not(.d-none) input[type=text]').set('Box 3')
      click_button 'Continue'

      expect(page).to have_css('.saved-item', text: 'Box 1')
      expect(page).to have_css('.saved-item', text: 'Box 2')
      expect(page).to have_css('[data-content-id] .selected-item-title', text: 'Box 3')

      fill_in 'Requested pages', with: 'Pages 1-10'
      click_button 'Submit request'
      expect(page).to have_css('.confirmation')
      expect(PatronRequest.last.patron_request_items.map(&:title)).to contain_exactly('Box 1', 'Box 2', 'Box 3')
    end

    it 'disables the "Continue" button while a manual-input row is empty' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      within('#items-accordion') do
        expect(page).to have_no_button 'Delete'
        expect(page).to have_button('Continue', disabled: true)

        first('[data-manual-items-row] input[type=text]').set('Box 1')
        expect(page).to have_button('Continue', disabled: false)

        click_button 'Add container'
        expect(page).to have_button('Continue', disabled: true)

        all('[data-manual-items-row] input[type=text]')[1].set('Box 2')
        expect(page).to have_button 'Delete', count: 2
        expect(page).to have_button('Continue', disabled: false)
      end
    end

    it 'allows users to input boxes manually' do # rubocop:disable RSpec/ExampleLength
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      expect(page).to have_text('New request')
      expect(page).to have_text('Hilton (Ozzie) Collection')

      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      first('[data-manual-items-row] input[type=text]').set('Box 1')
      click_button 'Add container'
      all('[data-manual-items-row] input[type=text]')[1].set('Box 24 ')
      click_button 'Add container'
      all('[data-manual-items-row] input[type=text]')[2].set('Box 25 ')
      within(all('[data-manual-items-row]')[1]) { click_button 'Delete' }

      click_button 'Continue'

      expect(page).to have_text('Requested pages')
      expect(page).to have_text('Box 1')
      fill_in 'Requested pages', with: 'Pages 1-10'
      fill_in 'Additional information', with: 'Testing only'
      click_button 'Next item'

      expect(page).to have_text('Box 25')
      fill_in 'Requested pages', with: 'Pages 10-14'
      fill_in 'Additional information', with: 'Testing only'

      click_button 'Submit request'

      expect(page).to have_css('.confirmation')

      expect do
        perform_enqueued_jobs
      end.to change(StubAeonClient::Request, :count).by(2)
      expect(PatronRequest.last.patron_request_items.length).to eq 2

      expect(StubAeonClient::Request.last(2)).to contain_exactly(
        have_attributes(
          callNumber: 'ARS.0052',
          itemVolume: 'Box 1',
          itemInfo5: 'Pages 1-10',
          specialRequest: 'Testing only',
          username: user.email_address,
          site: 'ARS'
        ),
        have_attributes(
          callNumber: 'ARS.0052',
          itemVolume: 'Box 25',
          itemInfo5: 'Pages 10-14',
          specialRequest: 'Testing only',
          username: user.email_address,
          site: 'ARS'
        )
      )
    end

    it 'does not display view container modal for reading room appointment' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')
      choose 'Reading room appointment'
      click_button 'Continue'

      first('[data-manual-items-row] input[type=text]').set('Box 1')
      click_button 'Add container'
      all('[data-manual-items-row] input[type=text]')[1].set('Box 24 ')
      click_button 'Continue'

      # Expect no viewing modal links
      expect(page).to have_no_css('button[data-action="view-container-contents#openViewModal"]')
    end

    it 'does not display view container modal for digitization' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')
      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      first('[data-manual-items-row] input[type=text]').set('Box 1')
      click_button 'Add container'
      all('[data-manual-items-row] input[type=text]')[1].set('Box 24 ')
      click_button 'Continue'

      # Expect no viewing modal links
      expect(page).to have_no_css('button[data-action="view-container-contents#openViewModal"]')
    end
  end

  context 'with single item ead' do
    let(:eadxml) do
      Nokogiri::XML(File.read('spec/fixtures/a0112.xml')).tap(&:remove_namespaces!)
    end

    it 'shows list of users relevant appointments' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      expect(page).to have_text('New request')
      expect(page).to have_text('Pehrson (Elmer Walter) Photograph Album')

      choose 'Reading room appointment'

      expect(page).to have_text('Earliest appointment available:')

      click_button 'Continue'

      check 'Box 1'
      click_button 'Continue'

      expect(page).to have_no_css('.selected-items-container .accordion-button')
      expect(page).to have_css('.selected-item-title', text: 'Box 1')

      # In the Appointment step
      expect(page).to have_text('Field Reading Room')
      expect(page).to have_text('Hours: Monday - Friday, 9:00 - 4:45 pm')

      # In the Appointment step
      click_button 'Select appointment'
      click_button appointment_start_time.strftime('%b %-d')
    end

    context 'when there are no appointments' do
      let(:appointments) { [] }

      it 'shows appointment alert' do
        visit new_archives_request_path(value: 'http://example.com/ead.xml')

        expect(page).to have_text('New request')
        expect(page).to have_text('Pehrson (Elmer Walter) Photograph Album')

        choose 'Reading room appointment'

        expect(page).to have_text('Earliest appointment available:')

        click_button 'Continue'

        check 'Box 1'
        click_button 'Continue'

        expect(page).to have_no_css('.selected-items-container .accordion-button')
        expect(page).to have_css('.selected-item-title', text: 'Box 1')

        # In the Appointment step
        expect(page).to have_text('Field Reading Room')
        expect(page).to have_text('Hours: Monday - Friday, 9:00 - 4:45 pm')
        expect(page).to have_text('You don’t have any appointments yet. Create one to continue.')
        expect(page).to have_button('Select appointment', disabled: true)
      end
    end

    it 'shows expanded item info for digitization request' do
      visit new_archives_request_path(value: 'http://example.com/ead.xml')
      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      check 'Box 1'
      click_button 'Continue'

      within('.selected-items-container .accordion-item', text: 'Box 1') do
        expect(page).to have_css('.accordion-button[disabled][aria-expanded="true"]')
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

      expect(page).to have_text('Pehrson (Elmer Walter) Photograph Album')
      expect(page).to have_text('Log in with SUNet ID')
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
      expect(page).to have_text 'Your library account does not include an email address, which is required to complete this request.'
    end
  end

  context 'with invalid or missing EAD XML' do
    let(:eadxml) { Nokogiri::XML('<ead/>') } # valid enough for Ead::Document.new, won't actually be used

    before do
      allow(EadClient).to receive(:fetch).and_raise(EadClient::InvalidDocument)
    end

    it 'shows an invalid document error' do
      visit new_archives_request_path(value: 'http://example.com/not-an-ead.xml')

      expect(page).to have_text('Missing or invalid EAD XML')
      expect(page).to have_text('Please check your finding aid source')
    end

    context 'when a network error occurs instead' do
      before do
        allow(EadClient).to receive(:fetch).and_raise(EadClient::Error)
      end

      it 'shows a generic error' do
        visit new_archives_request_path(value: 'http://example.com/ead.xml')

        expect(page).to have_text('Error Loading Collection Information')
        expect(page).to have_text('Please try again later')
      end
    end
  end
end
