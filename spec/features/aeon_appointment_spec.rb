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
                    activities_for: [],
                    available_appointments:)
  end
  let(:available_appointments) do
    [instance_double(Aeon::AvailableAppointment,
                     start_time: DateTime.new(2026, 2, 19),
                     maximum_appointment_length: 210.minutes)]
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
        expect(page).to have_text 'Create new appointment'
        expect(page).to have_text 'Materials must be used in their associated reading room'
        select 'Field Reading Room'
        click_on 'Continue'

        expect(page).to have_text 'Create new appointment Field Reading Room', normalize_ws: true
        expect(page).to have_text 'An appointment must be scheduled at least 5 business days in advance to access items'
        expect(page).to have_text 'Field Reading Room is open Monday - Friday, 9:00 - 4:45 pm'
        expect(page).to have_text 'Earliest appointment available: Thursday, Feb 19, 2026'
        expect(page).to have_field('aeon_appointment[date]', type: 'date')
        expect(page).to have_no_text('Duration')
        click_on 'Cancel'
      end
      expect(page).to have_no_css '.modal'
    end

    it 'opens and closes the create new appointment modal for ARS' do
      click_on 'Create new appointment'
      expect(page).to have_css '.modal'
      within '.modal' do
        expect(page).to have_text 'Create new appointment'
        select 'Archive of Recorded Sound'
        click_on 'Continue'

        expect(page).to have_text 'Create new appointment Archive of Recorded Sound', normalize_ws: true
        expect(page).to have_text(
          'Archive of Recorded Sound is open Monday - Wednesday, 9:00 - 3:00 pm, ' \
          'Thursday, 9:00 - 11:00 am and 12:00 - 3:00 pm, Friday, 9:00 - 3:00 pm'
        )
        expect(page).to have_field('aeon_appointment[date]', type: 'date')
        expect(page).to have_text('Duration')
        expect(page).to have_text('Available time slots')
        click_on 'Cancel'
      end
      expect(page).to have_no_css '.modal'
    end
  end

  describe 'edit appointment modal' do
    it 'opens and closes modal for day only reading room' do
      click_on 'Edit'
      within '.modal' do
        expect(page).to have_text 'Change appointment'
        expect(page).to have_text 'Field Reading Room'
        expect(page).to have_text 'Current'
        expect(page).to have_text appointment.date.strftime('%b %e, %Y')
        expect(page).to have_no_text appointment.start_time.strftime('%l:%M %p')
        expect(page).to have_text 'New'
        expect(page).to have_text 'Select date'
        expect(page).to have_text '1 item will move to the new appointment.'
        # Input a date a month from now
        fill_in 'aeon_appointment_date', with: (Time.zone.today >> 1).strftime('%m%d%Y')
        expect(page).to have_text (Time.zone.today >> 1).strftime('%b %e, %Y')
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
        expect(page).to have_text 'Cancel appointment?'
        choose('cancel_items_false')
        expect(page).to have_text '1 item assigned to this appointment.'
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
        expect(page).to have_text 'Cancel appointment?'
        choose('cancel_items_true')
        expect(page).to have_text '1 item assigned to this appointment.'
        click_on 'Yes, cancel appointment'
      end
      expect(page).to have_no_css '.modal'

      expect(stub_aeon_client).to have_received(:update_request_route).with({ status: 'Cancelled by User', transaction_number: 100 })
      expect(stub_aeon_client).to have_received(:cancel_appointment).with(23)
    end
  end
end
