# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating an Aeon patron request in the redesign', :js do
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
  let(:reading_rooms) { JSON.load_file('spec/fixtures/reading_rooms.json').map { |room| Aeon::ReadingRoom.from_dynamic(room) } }
  let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }
  let(:stub_aeon_client) do
    instance_double(AeonClient, find_user: aeon_user, create_request: created_request, update_request_route: nil,
                                reading_rooms:, available_appointments:, activities_for: [], requests_for: [])
  end
  let(:created_request) { instance_double(Aeon::Request, id: 123, transaction_number: 'abc123', submitted?: true, saved_for_later?: false, valid?: true) }
  let(:available_appointments) do
    [Aeon::AvailableAppointment.new(start_time: DateTime.new(2026, 2, 19),
                                    maximum_appointment_length: 210.minutes)]
  end

  let(:appointments) do
    [
      build(:aeon_appointment,
            start_time: DateTime.new(2026, 2, 19, 12, 0, 0),
            stop_time: DateTime.new(2026, 2, 19, 13, 0, 0),
            id: 1,
            requests: [instance_double(Aeon::Request, cancelled?: false)],
            reading_room: reading_rooms.last),
      build(:aeon_appointment,
            start_time: DateTime.new(2026, 2, 20, 13, 0, 0),
            stop_time: DateTime.new(2026, 2, 20, 14, 0, 0),
            id: 2,
            requests: [instance_double(Aeon::Request, cancelled?: false)],
            reading_room: reading_rooms.first)
    ]
  end

  before do
    allow(Folio::Patron).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
    login_as(current_user)
    stub_folio_instance_json(build(folio_instance))
    allow(Settings.features).to receive(:requests_redesign).and_return(true)
    login_as(current_user)

    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    appointments.each { |appt| allow(appt).to receive(:editable?).and_return(true) }
    allow(aeon_user).to receive_messages(appointments: appointments,
                                         requests: [])

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

      perform_enqueued_jobs
      expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                        call_number: 'ABC 123'
                                                                      ))
    end

    it 'allows the user to submit a reading room request' do
      choose 'Reading room appointment'

      click_button 'Continue'

      # In the Appointment step
      click_button 'Select appointment'
      click_button 'Feb 19'

      fill_in 'Additional information', with: 'Testing only'

      click_button 'Submit request'

      expect(page).to have_text 'We received your reading room access request!'

      perform_enqueued_jobs
      expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                        call_number: 'ABC 123'
                                                                      ))
    end
  end

  context 'with an activity request' do
    let(:activity) { build(:aeon_activity, id: 42, users: [aeon_user]) }
    let(:stub_aeon_client) do
      instance_double(AeonClient, find_user: aeon_user, create_request: created_request, update_request_route: nil,
                                  reading_rooms:, available_appointments:, activities_for: [activity])
    end

    before do
      allow(stub_aeon_client).to receive(:requests_for) do
        patron_request = PatronRequest.last
        # Exercise the confirmation screen polling
        next [] unless patron_request&.submitted_to_aeon_at

        [build(:aeon_request, :submitted,
               activity_id: 42,
               web_request_form: 'multiple',
               reference_number: patron_request.to_global_id.to_s)]
      end
    end

    it 'shows the activity-grouped confirmation after submission' do
      choose 'Activity (e.g., class visit or exhibit)'
      click_button 'Continue'

      check 'An Aeon Activity'

      click_button 'Submit request'

      expect(page).to have_text 'We received your activities request'

      perform_enqueued_jobs

      expect(page).to have_text 'An Aeon Activity'
      expect(page).to have_text 'Request #307'
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

      perform_enqueued_jobs
      expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                        call_number: 'ABC 123'
                                                                      ))

      expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                        call_number: 'ABC 321'
                                                                      ))
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
