# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating an Aeon patron request in the redesign', :js do
  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true, ldap_attributes: {}) }
  let(:bib_data) { :special_collections_single_holding }
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
    instance_double(AeonClient, find_user: aeon_user, create_request: { success: true }, reading_rooms:, available_appointments:)
  end
  let(:available_appointments) do
    [instance_double(Aeon::AvailableAppointment,
                     start_time: DateTime.new(2026, 2, 19),
                     maximum_appointment_length: 210.minutes)]
  end

  before do
    allow(Folio::Patron).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
    login_as(current_user)
    stub_bib_data_json(build(bib_data))
    allow(Settings.features).to receive(:requests_redesign).and_return(true)
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

    visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SPEC-STACKS')
  end

  context 'with a single holding' do
    it 'allows the user to submit a digitization request' do
      expect(page).to have_content 'Request type'
      expect(page).to have_no_content 'Select item'

      choose 'Digitization'

      click_button 'Continue'

      fill_in 'Requested pages', with: 'Pages 1-10'

      click_button 'Continue'
      check 'I agree to these terms'
    end
  end

  context 'with multiple holdings' do
    let(:bib_data) { :special_collections_holdings }

    it 'allows the user to submit a digitization request' do
      expect(page).to have_content 'Request type'
      expect(page).to have_content 'Select item(s)'

      choose 'Digitization'

      click_button 'Continue'
    end
  end
end
