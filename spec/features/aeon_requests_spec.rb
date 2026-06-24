# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Requests', :js do
  use_stub_aeon_client

  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true) }

  let(:aeon_user) { StubAeonClient::User.create(username: user.email_address, authType: 'Default') }
  let(:appointment) do
    create(:remote_aeon_appointment, username: user.email_address, reading_room:, startTime: 1.week.from_now,
                                     stopTime: 1.week.from_now + 1.hour)
  end
  let(:reading_room) { StubAeonClient::ReadingRoom.find_by(name: 'Field Reading Room') }
  let(:saved_for_later_request) do
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
    saved_for_later_request
    submitted_request

    login_as(current_user)
  end

  describe 'saved for later' do
    let(:appointment_label) { I18n.l(1.week.from_now, format: :date_only).to_s }

    it 'displays requests that are saved for later' do
      visit aeon_requests_path(kind: 'saved_for_later')

      expect(page).to have_text('Slow poetry in America : a poetry quarterly')
      expect(page).to have_no_text('Medium poetry in America : a poetry quarterly')
    end

    it 'displays appointments' do
      visit aeon_requests_path(kind: 'saved_for_later')

      within '#aeon_appointments_sidebar' do
        expect(page).to have_text(appointment_label)
        expect(page).to have_text('Item limit: 1/10')
      end
    end

    it 'allows the user to assign a saved for later request to an appointment' do
      visit aeon_requests_path(kind: 'saved_for_later')

      click_on 'Add appointment'
      click_on 'Select appointment'
      click_on appointment_label
      click_on 'Submit request'

      within '#aeon_appointments_sidebar' do
        expect(page).to have_text(appointment_label)
        expect(page).to have_text('Item limit: 2/10')
      end

      expect(page).to have_no_text('Slow poetry in America : a poetry quarterly')
    end

    context 'when creating a new appointment' do
      let(:appointment) { nil }
      let(:submitted_request) { nil }

      it 'allows the user to assign a saved for later request' do
        visit aeon_requests_path(kind: 'saved_for_later')

        click_on 'Add appointment'
        click_on 'Create new appointment'
        click_on 'Select a date'
        click_on 'Next month'

        first('td[role="gridcell"]:not(:has(buton:disabled))').click
        click_on 'Save'

        within '#aeon-appointments-frame[complete] #aeon_appointments_sidebar' do
          expect(page).to have_text('Item limit: 0/10')
        end

        click_on 'Submit request'
        expect(page).to have_no_text('Slow poetry in America : a poetry quarterly')

        within '#aeon_appointments_sidebar' do
          expect(page).to have_text('Item limit: 1/10')
        end
      end
    end

    it 'allows the user to cancel the request' do
      visit aeon_requests_path(kind: 'saved_for_later')

      click_on 'Delete Slow poetry in America'

      click_on 'Yes - Delete'

      expect(page).to have_no_text('Slow poetry in America : a poetry quarterly')
    end
  end
end
