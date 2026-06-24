# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Appointments', :js do
  use_stub_aeon_client

  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true) }

  let(:aeon_user) { StubAeonClient::User.create(username: user.email_address, authType: 'Default') }
  let(:appointment) do
    create(:remote_aeon_appointment, username: user.email_address, reading_room:, startTime: appointment_start_time,
                                     stopTime: appointment_start_time + 1.hour)
  end
  let(:appointment_start_time) { 1.week.from_now }
  let(:reading_room) { StubAeonClient::ReadingRoom.find_by(name: 'Field Reading Room') }
  let(:draft_request) do
    StubAeonClient::Request.create(
      callNumber: 'PR9195.1 .S56 NO.1',
      itemTitle: 'Slow poetry in America : a poetry quarterly',
      username: aeon_user.username,
      webRequestForm: 'multiple',
      site: 'SPECUA'
    )
  end

  let(:submitted_request) do
    StubAeonClient::Request.create(
      callNumber: 'assigned call number 1',
      itemTitle: 'Medium poetry in America : a poetry quarterly',
      appointmentID: appointment.id,
      username: aeon_user.username,
      webRequestForm: 'multiple',
      transactionStatus: 3
    )
  end

  before do
    draft_request
    submitted_request

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
        expect(page).to have_text 'Earliest appointment available:'
        expect(page).to have_css 'label', text: 'Date'
        expect(page).to have_no_text('Duration')

        click_on 'Select a date'
        click_on 'Next month'

        first('td[role="gridcell"]:not(:has(button:disabled))').click
        expect(page).to have_css('#aeon_appointment_start_time', visible: :all)

        click_on 'Save'
      end
      expect(page).to have_no_css '.modal'
    end

    it 'opens and closes the create new appointment modal for ARS' do # rubocop:disable RSpec/ExampleLength
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
        expect(page).to have_css 'label', text: 'Date'
        expect(page).to have_text('Duration')
        expect(page).to have_text('Available time slots')

        click_on 'Select a date'
        click_on 'Next month'

        first('td[role="gridcell"]:not(:has(button:disabled))').click

        find(:label, text: '2 hours').click
        find(:label, text: '1:00 pm').click

        click_on 'Save'
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
        expect(page).to have_text appointment_start_time.strftime('%b %-d, %Y')
        expect(page).to have_no_text appointment_start_time.strftime('%l:%M %p')
        expect(page).to have_text 'New'
        expect(page).to have_text 'Select date'
        expect(page).to have_text '1 item will move to the new appointment.'

        click_on appointment_start_time.strftime('%b %-d, %Y')
        click_on 'Next month'

        first('td[role="gridcell"]:not(:has(button:disabled))').click
        expect(page).to have_css('#aeon_appointment_start_time', visible: :all)

        click_on 'Save'
      end
      expect(page).to have_no_css '.modal'
    end
  end

  describe 'saving an active request for later' do
    it 'moves the request into saved for later' do
      within "#aeon_request_#{submitted_request.id}" do
        click_on 'Save for later'
        expect(page).to have_no_link 'Add items'
      end

      within '#saved_for_later_aeon_requests_sidebar' do
        expect(page).to have_css "#aeon_request_#{submitted_request.id}"
      end

      within '#aeon_appointments' do
        expect(page).to have_no_css "#aeon_request_#{submitted_request.id}"
        expect(page).to have_text 'No items have been requested for this appointment.'
        expect(page).to have_link 'Add items'
      end
    end
  end

  describe 'assigning a draft request to an appointment' do
    it 'moves the request into the appointment' do
      within '#saved_for_later_aeon_requests_sidebar' do
        click_on 'Appointment'
        click_on I18n.l(1.week.from_now, format: :date_only).to_s
      end

      within '#aeon_appointments' do
        expect(page).to have_text('Slow poetry in America : a poetry quarterly')
      end
    end
  end

  describe 'with multiple requests' do
    let(:second_draft_request) do
      StubAeonClient::Request.create(
        callNumber: 'PR9195.1 .S56 NO.2',
        itemTitle: 'Slow poetry in America : a poetry quarterly',
        username: aeon_user.username,
        webRequestForm: 'multiple',
        site: 'SPECUA'
      )
    end

    before do
      second_draft_request
    end

    describe 'assigning a draft request to an appointment' do
      it 'moves the request into the appointment' do # rubocop:disable RSpec/ExampleLength
        visit aeon_appointments_path
        within '#saved_for_later_aeon_requests_sidebar' do
          within "#aeon_request_#{draft_request.id}" do
            click_on 'Appointment'
          end
          expect(page).to have_text("#{I18n.l(1.week.from_now, format: :date_only)} 1 item")
          click_on I18n.l(1.week.from_now, format: :date_only).to_s
        end

        within '#aeon_appointments' do
          expect(page).to have_text('Slow poetry in America : a poetry quarterly', count: 1)
          expect(page).to have_text('Item limit: 2/10')
        end

        within '#saved_for_later_aeon_requests_sidebar' do
          within "#aeon_request_#{second_draft_request.id}" do
            click_on 'Appointment'
          end
          expect(page).to have_text("#{I18n.l(1.week.from_now, format: :date_only)} 2 items")
          click_on I18n.l(1.week.from_now, format: :date_only).to_s
        end

        within '#saved_for_later_aeon_requests_sidebar' do
          expect(page).to have_no_text('Slow poetry in America')
        end

        within '#aeon_appointments' do
          expect(page).to have_text('Slow poetry in America : a poetry quarterly', count: 1)
          expect(page).to have_text('Item limit: 3/10')

          within "#aeon_request_#{second_draft_request.id}" do
            click_on 'Save for later'
          end
        end

        within '#saved_for_later_aeon_requests_sidebar' do
          expect(page).to have_text('Slow poetry in America')
        end
      end
    end
  end

  describe 'delete appointment modal' do
    it 'moves requests into saved for later' do
      click_on 'Delete appointment'
      expect(page).to have_css '.modal'
      perform_enqueued_jobs do
        expect(page).to have_text 'Cancel appointment?'
        choose('cancel_items_false')
        expect(page).to have_text '1 item is assigned to this appointment.'
        click_on 'Yes, cancel appointment'
      end
      expect(page).to have_no_css '.modal'
      expect(page).to have_no_css "#aeon_appointment_#{appointment.id}"

      # TODO: need to add turbo response to update the sidebar
      # within '#saved_for_later_aeon_requests_sidebar' do
      #   expect(page).to have_css "#aeon_request_#{submitted_request.id}"
      # end
    end

    it 'deletes the requests' do
      click_on 'Delete appointment'
      expect(page).to have_css '.modal'
      perform_enqueued_jobs do
        expect(page).to have_text 'Cancel appointment?'
        choose('cancel_items_true')
        expect(page).to have_text '1 item is assigned to this appointment.'
        click_on 'Yes, cancel appointment'
      end
      expect(page).to have_no_css '.modal'
      expect(page).to have_no_css "#aeon_appointment_#{appointment.id}"

      within '#saved_for_later_aeon_requests_sidebar' do
        expect(page).to have_no_css "#aeon_request_#{submitted_request.id}"
      end
    end
  end
end
