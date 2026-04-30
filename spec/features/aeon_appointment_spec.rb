# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Appointments', :js do
  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true) }
  let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }
  let(:reading_rooms) { JSON.load_file('spec/fixtures/reading_rooms.json').map { |rr| Aeon::ReadingRoom.from_dynamic(rr) } }

  let(:field_reading_room) { reading_rooms[-1] }
  let(:appointment) { build(:aeon_appointment, reading_room: field_reading_room, start_time: 1.week.from_now) }
  let(:queue) do
    Aeon::Queue.new(id: 8, queue_name: 'Awaiting Staff Review', queue_type: 'Transaction')
  end
  let(:stub_aeon_client) do
    instance_double(AeonClient,
                    find_user: aeon_user,
                    appointments_for: [appointment],
                    find_queue: queue,
                    update_request: build(:aeon_request, transaction_number: 100),
                    update_request_route: build(:aeon_request, transaction_number: 100),
                    requests_for: [build(:aeon_request, transaction_number: 100, username: user.email_address, appointment: appointment)],
                    cancel_appointment: [],
                    reading_rooms:,
                    available_appointments: [])
  end

  before do
    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    login_as(current_user)
    visit aeon_appointments_path
  end

  describe 'create appointment modal' do
    it 'opens and closes the create new appointment modal for field reading room' do
      click_on 'Create new appointment'
      expect(page).to have_css '.modal'
      within '.modal' do
        expect(page).to have_content 'Create new appointment'
        select 'Field Reading Room'
        click_on 'Continue'

        expect(page).to have_content 'Create new appointmentField Reading Room'
        expect(page).to have_field('aeon_appointment[date]', type: 'date')
        expect(page).to have_no_content('Duration')
        click_on 'Cancel'
      end
      expect(page).to have_no_css '.modal'
    end

    it 'opens and closes the create new appointment modal for ARS' do
      click_on 'Create new appointment'
      expect(page).to have_css '.modal'
      within '.modal' do
        expect(page).to have_content 'Create new appointment'
        select 'Archive of Recorded Sound'
        click_on 'Continue'

        expect(page).to have_content 'Create new appointmentArchive of Recorded Sound'
        expect(page).to have_field('aeon_appointment[date]', type: 'date')
        expect(page).to have_content('Duration')
        expect(page).to have_content('Available time slots')
        click_on 'Cancel'
      end
      expect(page).to have_no_css '.modal'
    end
  end

  describe 'edit appointment modal' do
    it 'opens and closes the edit appointment modal' do
      click_on 'Edit'
      within '.modal' do
        expect(page).to have_content 'Edit appointment'
        expect(page).to have_content 'Field Reading Room'
        click_on 'Cancel'
      end
      expect(page).to have_no_css '.modal'
    end
  end

  describe 'redrafting a request' do
    it 'moves the request into draft' do
      within '#aeon_request_100' do
        click_on 'Remove'
      end

      expect(page).to have_no_css '#aeon_request_100'

      expect(stub_aeon_client).to have_received(:update_request_route).with({ status: 'Awaiting User Review',
                                                                              transaction_number: 100 })
    end
  end

  describe 'delete appointment modal' do
    it 'moves requests into draft' do
      click_on 'Delete appointment'
      expect(page).to have_css '.modal'
      perform_enqueued_jobs do
        expect(page).to have_content 'Cancel appointment?'
        choose('cancel_items_false')
        expect(page).to have_content '1 item assigned to this appointment.'
        click_on 'Yes, cancel appointment'
      end
      expect(page).to have_no_css '.modal'

      expect(stub_aeon_client).to have_received(:update_request_route).with({ status: 'Awaiting User Review',
                                                                              transaction_number: 100 })
      expect(stub_aeon_client).to have_received(:cancel_appointment).with(23)
    end

    it 'deletes the requests' do
      click_on 'Delete appointment'
      expect(page).to have_css '.modal'
      perform_enqueued_jobs do
        expect(page).to have_content 'Cancel appointment?'
        choose('cancel_items_true')
        expect(page).to have_content '1 item assigned to this appointment.'
        click_on 'Yes, cancel appointment'
      end
      expect(page).to have_no_css '.modal'

      expect(stub_aeon_client).to have_received(:update_request_route).with({ status: 'Cancelled by User', transaction_number: 100 })
      expect(stub_aeon_client).to have_received(:cancel_appointment).with(23)
    end
  end
end
