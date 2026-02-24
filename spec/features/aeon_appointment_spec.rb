# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Appointments', :js do
  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true) }
  let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }
  let(:reading_room) { build(:aeon_reading_room) }
  let(:appointment) { build(:aeon_appointment, reading_room: reading_room, start_time: 1.week.from_now) }
  let(:stub_aeon_client) do
    instance_double(AeonClient,
                    find_user: aeon_user,
                    appointments_for: [appointment],
                    requests_for: [],
                    reading_rooms: [reading_room],
                    available_appointments: [])
  end

  before do
    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    login_as(current_user)
    visit aeon_appointments_path
  end

  describe 'create appointment modal' do
    it 'opens and closes the create new appointment modal' do
      click_on 'Create new appointment'
      expect(page).to have_css '#modal'
      within '#modal' do
        expect(page).to have_content 'New appointment'
        click_on 'Cancel'
      end
      expect(page).to have_no_css '#modal'
    end
  end

  describe 'edit appointment modal' do
    it 'opens and closes the edit appointment modal' do
      click_on 'Edit'
      within '#modal' do
        expect(page).to have_content 'Edit appointment'
        expect(page).to have_content 'Field Reading Room'
        click_on 'Cancel'
      end
      expect(page).to have_no_css '#modal'
    end
  end
end
