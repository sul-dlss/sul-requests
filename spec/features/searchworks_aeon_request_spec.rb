# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating an Aeon patron request in the redesign', :js do
  use_stub_aeon_client

  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true, ldap_attributes: {}) }
  let(:folio_instance) { :special_collections_single_holding }
  let(:patron) do
    instance_double(Folio::Patron, id: user.patron_key, username: 'auser', display_name: 'A User', exists?: true, email: nil,
                                   patron_description: 'faculty',
                                   patron_group_name: 'faculty',
                                   blocked?: false, proxies: [], sponsors: [], sponsor?: false, proxy?: false,
                                   allowed_request_types: %w[Hold Recall Page])
  end
  let(:aeon_user) { StubAeonClient::User.create(username: user.email_address, authType: 'Default') }
  let(:reading_room) { StubAeonClient::ReadingRoom.find_by(name: 'Field Reading Room') }

  let(:appointment_start_time) { 1.week.from_now }
  let(:appointments) do
    [
      create(:remote_aeon_appointment, username: user.email_address, reading_room:, startTime: appointment_start_time,
                                       stopTime: appointment_start_time + 1.hour),

      create(:remote_aeon_appointment, username: user.email_address, reading_room:, startTime: appointment_start_time + 1.day,
                                       stopTime: appointment_start_time + 1.day + 2.hours)
    ]
  end

  before do
    allow(Folio::Patron).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
    login_as(current_user)
    stub_folio_instance_json(build(folio_instance))
    allow(Settings.features).to receive(:requests_redesign).and_return(true)
    login_as(current_user)

    aeon_user
    appointments

    visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SPEC-STACKS')
  end

  context 'with a single holding' do
    it 'allows the user to submit a digitization request' do
      expect(page).to have_text 'Request type'
      expect(page).to have_no_text 'Select item'

      choose 'Digitization'
      check 'I agree to these terms'

      click_button 'Continue'

      within('.selected-items-container') do
        within('.accordion-item', text: 'ABC 123') do
          expect(page).to have_css('.accordion-button[disabled][aria-expanded="true"]')
        end
      end

      fill_in 'Requested pages', with: 'Pages 1-10'
      choose 'Yes'
      fill_in 'Additional information', with: 'Testing only'

      click_button 'Submit request'

      expect(page).to have_text 'We received your digitization request!'

      expect do
        perform_enqueued_jobs
      end.to change(StubAeonClient::Request, :count).by(1)

      expect(StubAeonClient::Request.last).to have_attributes(
        callNumber: 'ABC 123'
      )
    end

    it 'allows the user to submit a reading room request' do
      # Start down the digitization path and fill in a note we later abandon.
      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'
      fill_in 'Requested pages', with: 'Pages 1-10'
      choose 'Yes'
      fill_in 'Additional information', with: 'abandoned digitization note'

      # Change our mind: go back to the request-type step and switch flows.
      within('#request-type-accordion') { click_button 'Edit' }
      choose 'Reading room appointment'
      click_button 'Continue'

      # In the Appointment step
      click_button 'Select appointment'
      click_button appointment_start_time.strftime('%b %-d')

      fill_in 'Additional information', with: 'reading room note'

      click_button 'Submit request'

      expect(page).to have_text 'We received your reading room access request!'

      expect do
        perform_enqueued_jobs
      end.to change(StubAeonClient::Request, :count).by(1)

      expect(StubAeonClient::Request.last).to have_attributes(
        callNumber: 'ABC 123',
        specialRequest: 'reading room note'
      )
    end
  end

  context 'with an activity request' do
    let(:aeon_activity) do
      create(:remote_aeon_activity, users: [{ username: aeon_user.username }])
    end

    before do
      aeon_activity
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SPEC-STACKS')
    end

    it 'shows the activity-grouped confirmation after submission' do
      choose 'Activity (e.g., class visit or exhibit)'
      click_button 'Continue'

      check 'An Aeon Activity'

      click_button 'Submit request'

      expect(page).to have_text 'We received your activities request'

      expect do
        perform_enqueued_jobs
        expect(page).to have_css('#aeon-confirmation .confirmation')
      end.to change(StubAeonClient::Request, :count).by(1)

      expect(page).to have_text 'An Aeon Activity'
      expect(page).to have_text "Request ##{StubAeonClient::Request.last.id}"
    end
  end

  context 'with multiple holdings' do
    let(:folio_instance) { :special_collections_holdings }

    it 'has working save for later undo and delete buttons' do
      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      check 'ABC 321'
      click_button 'Continue'

      click_button 'Save for later'
      expect(page).to have_css('.saved-item', text: 'ABC 321')

      click_button 'Undo'

      expect(page).to have_css('.selected-item-title', text: 'ABC 321')
      click_button 'Save for later'

      click_button 'Delete ABC 321'

      expect(page).to have_css('.item-table')
    end

    it 'allows the user to submit a digitization request' do # rubocop:disable RSpec/ExampleLength
      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      # Proceed with 1 selected item
      check 'ABC 123'
      click_button 'Continue'
      within('.selected-items-container .accordion-item', text: 'ABC 123') do
        expect(page).to have_css('.accordion-button[disabled][aria-expanded="true"]')
      end

      # Go back to edit item selection
      within('#items-accordion') do
        click_button 'Edit'
      end

      # Now there are 2 selected items
      check 'ABC 321'
      click_button 'Continue'

      within('.digitization-accordion') do
        within('.accordion-item', text: 'ABC 123') do
          expect(page).to have_css('.accordion-button[aria-expanded="true"]')
        end
        within('.accordion-item', text: 'ABC 321') do
          expect(page).to have_css('.accordion-button[aria-expanded="false"]')
        end
        expect(page).to have_no_css('.accordion-button[disabled]')
      end

      fill_in 'Requested pages', with: 'Pages 1-10'
      choose 'Yes'
      click_button 'Next item'
      fill_in 'Requested pages', with: 'Pages 11-20'
      choose 'No'

      click_button 'Submit request'

      expect(page).to have_text 'We received your digitization request!'

      expect do
        perform_enqueued_jobs
      end.to change(StubAeonClient::Request, :count).by(2)

      expect(StubAeonClient::Request.last(2).map(&:callNumber)).to contain_exactly('ABC 123', 'ABC 321')
    end

    it 'allows the user to save items for later' do # rubocop:disable RSpec/ExampleLength
      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      check 'ABC 123'
      check 'ABC 321'
      click_button 'Continue'

      # Submit disabled: no items are complete yet
      expect(page).to have_button('Submit request', disabled: true)

      fill_in 'Requested pages', with: 'Pages 1-10'
      choose 'Yes'
      click_button 'Next item'

      # Submit still disabled: second item is incomplete
      expect(page).to have_button('Submit request', disabled: true)

      find('[data-content-id]', text: 'ABC 321').click_button('Save for later')
      expect(page).to have_css('.saved-item', text: 'ABC 321')

      # Submit enabled: first item complete, second saved for later
      expect(page).to have_button('Submit request', disabled: false)

      within('[data-save-for-later-target="list"]') do
        expect(page).to have_text 'ABC 321'
        click_button 'Undo'
      end

      # Submit disabled again: restored item is incomplete
      expect(page).to have_button('Submit request', disabled: true)

      expect(page).to have_no_css '.saved-item'

      within('.digitization-accordion') do
        expect(page).to have_text 'ABC 321'
      end
    end
  end
end
