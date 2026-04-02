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
                                reading_rooms:, available_appointments:)
  end
  let(:created_request) { instance_double(Aeon::Request, id: 123, transaction_number: 'abc123', submitted?: true, draft?: false, valid?: true) }
  let(:available_appointments) do
    [instance_double(Aeon::AvailableAppointment,
                     start_time: DateTime.new(2026, 2, 19),
                     maximum_appointment_length: 210.minutes)]
  end

  before do
    allow(Folio::Patron).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
    login_as(current_user)
    stub_folio_instance_json(build(folio_instance))
    allow(Settings.features).to receive(:requests_redesign).and_return(true)
    login_as(current_user)

    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    allow(aeon_user).to receive_messages(appointments: [
                                           instance_double(Aeon::Appointment,
                                                           start_time: DateTime.new(2026, 2, 19, 12, 0, 0),
                                                           stop_time: DateTime.new(2026, 2, 19, 13, 0, 0),
                                                           id: 1,
                                                           editable?: true,
                                                           sort_key: 2,
                                                           requests: [instance_double(Aeon::Request)],
                                                           reading_room: reading_rooms.last),
                                           instance_double(Aeon::Appointment,
                                                           start_time: DateTime.new(2026, 2, 20, 13, 0, 0),
                                                           stop_time: DateTime.new(2026, 2, 20, 14, 0, 0),
                                                           id: 1,
                                                           editable?: true,
                                                           sort_key: 2,
                                                           requests: [instance_double(Aeon::Request)],
                                                           reading_room: reading_rooms.first)
                                         ],
                                         requests: [])

    visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SPEC-STACKS')
  end

  context 'with a single holding' do
    it 'allows the user to submit a digitization request' do
      expect(page).to have_content 'Request type'
      expect(page).to have_no_content 'Select item'

      choose 'Digitization'
      check 'I agree to these terms'

      click_button 'Continue'

      # TODO: Re-enable when accordion button disabled state is working
      # within('.selected-items-container') do
      # expect(page).to have_css('.accordion-button[disabled][aria-expanded="true"]', text: 'ABC 123')
      # end

      fill_in 'Requested pages', with: 'Pages 1-10'
      choose 'Yes'
      fill_in 'Additional information', with: 'Testing only'

      click_button 'Submit request'

      expect(page).to have_content 'We received your digitization request!'

      perform_enqueued_jobs
      expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                        call_number: 'ABC 123'
                                                                      ))
    end

    it 'allows the user to submit a reading room request' do
      choose 'Reading room appointment'

      click_button 'Continue'

      # In the Appointment step
      click_button 'Select existing appointment'
      click_button 'Feb 19'

      fill_in 'Additional information', with: 'Testing only'

      click_button 'Submit request'

      expect(page).to have_content 'We received your reading room access request!'

      perform_enqueued_jobs
      expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                        call_number: 'ABC 123'
                                                                      ))
    end
  end

  context 'with multiple holdings' do
    let(:folio_instance) { :special_collections_holdings }

    it 'allows the user to submit a digitization request' do # rubocop:disable RSpec/ExampleLength
      choose 'Digitization'
      check 'I agree to these terms'
      click_button 'Continue'

      # Proceed with 1 selected item
      check 'ABC 123'
      click_button 'Continue'
      within('.selected-items-container') do
        expect(page).to have_css('.accordion-button[disabled][aria-expanded="true"]', text: 'ABC 123')
      end

      # Go back to edit item selection
      within('#items-accordion') do
        click_button 'Edit'
      end

      # Now there are 2 selected items
      check 'ABC 321'
      click_button 'Continue'

      within('.digitization-accordion') do
        expect(page).to have_css('.accordion-button[aria-expanded="true"]', text: 'ABC 123')
        expect(page).to have_css('.accordion-button[aria-expanded="false"]', text: 'ABC 321')
        expect(page).to have_no_css('.accordion-button[disabled]')
      end

      fill_in 'Requested pages', with: 'Pages 1-10'
      choose 'Yes'
      click_button 'Next item'
      fill_in 'Requested pages', with: 'Pages 11-20'
      choose 'No'

      click_button 'Submit request'

      expect(page).to have_content 'We received your digitization request!'

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

      find('[data-content-id]', text: 'ABC 321').click_link('Save for later')
      expect(page).to have_css('.saved-item', text: 'ABC 321')

      # Submit enabled: first item complete, second saved for later
      expect(page).to have_button('Submit request', disabled: false)

      within('[data-save-for-later-target="list"]') do
        expect(page).to have_content 'ABC 321'
        click_link 'Undo'
      end

      # Submit disabled again: restored item is incomplete
      expect(page).to have_button('Submit request', disabled: true)

      expect(page).to have_no_css '.saved-item'

      within('.digitization-accordion') do
        expect(page).to have_content 'ABC 321'
      end
    end
  end
end
