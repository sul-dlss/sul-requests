# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Add items modal', :js do
  use_stub_aeon_client

  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true, patron_key: user.patron_key, ldap_attributes: {}) }

  let(:aeon_user) { StubAeonClient::User.create(username: user.email_address, authType: 'Default') }
  let(:appointment) do
    create(:remote_aeon_appointment, username: aeon_user.username, reading_room:, startTime: 1.week.from_now,
                                     stopTime: 1.week.from_now + 1.hour)
  end
  let(:reading_room) { StubAeonClient::ReadingRoom.find_by(name: 'Field Reading Room') }

  before do
    StubAeonClient::Request.create(
      id: 100,
      callNumber: 'PR9195.1 .S56 NO.1',
      itemTitle: 'Slow poetry in America : a poetry quarterly',
      username: aeon_user.username,
      webRequestForm: 'multiple',
      site: 'SPECUA'
    )

    StubAeonClient::Request.create(
      id: 101,
      callNumber: 'PR9195.1 .S56 NO.2',
      itemTitle: 'Slow poetry in America : a poetry quarterly',
      username: aeon_user.username,
      webRequestForm: 'multiple',
      site: 'SPECUA'
    )

    StubAeonClient::Request.create(
      id: 102,
      callNumber: 'PR9195.1 .S56 NO.2',
      itemTitle: 'Fast poetry in America : a poetry monthly',
      shippingOption: 'Electronic Delivery',
      username: aeon_user.username,
      webRequestForm: 'multiple',
      site: 'SPECUA'
    )

    StubAeonClient::Request.create(
      id: 103,
      callNumber: 'assigned call number 1',
      itemTitle: 'Medium poetry in America : a poetry quarterly',
      appointmentID: appointment.id,
      username: aeon_user.username,
      webRequestForm: 'multiple',
      transactionStatus: 3
    )

    StubAeonClient::Request.create(
      id: 104,
      callNumber: 'assigned call number 2',
      itemTitle: 'Medium poetry in America : a poetry quarterly',
      appointmentID: appointment.id,
      username: aeon_user.username,
      webRequestForm: 'multiple',
      transactionStatus: 3
    )

    login_as(current_user)
    visit aeon_appointments_path
  end

  it 'opens and submits add items' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
    click_link 'Add items'
    within '.modal' do
      expect(page).to have_no_text('Fast poetry in America : a poetry quarterly')
      click_on 'Items scheduled to use during this appointment'

      expect(page).to have_text('Slow poetry in America : a poetry quarterly', count: 1)
      expect(page).to have_css('#appointmentRequestsAccordion li', count: 2)
      expect(page).to have_text('Medium poetry in America : a poetry quarterly', count: 1)
      expect(page).to have_css('#savedForLaterRequestsAccordion li', count: 2)

      # Add slow poetry call number 1 to scheduled appointments
      find("button[data-transaction-number='100']", text: 'Add to appointment').click

      # expect a header to move into modal
      expect(page).to have_text('Slow poetry in America : a poetry quarterly', count: 2)
      expect(page).to have_css('#appointmentRequestsAccordion li', count: 3)
      expect(page).to have_text('Medium poetry in America : a poetry quarterly', count: 1)
      expect(page).to have_css('#savedForLaterRequestsAccordion li', count: 1)

      # Add slow poetry call number 2 to scheduled appointments
      find("button[data-transaction-number='101']", text: 'Add to appointment').click

      expect(page).to have_text('Slow poetry in America : a poetry quarterly', count: 1)
      expect(page).to have_css('#appointmentRequestsAccordion li', count: 4)
      expect(page).to have_text('Medium poetry in America : a poetry quarterly', count: 1)
      expect(page).to have_css('#savedForLaterRequestsAccordion li', count: 0)

      # Remove scheduled appointment and saved_for_later appointment
      find("button[data-transaction-number='103']", text: 'Save for later').click
      find("button[data-transaction-number='101']", text: 'Save for later').click

      expect(page).to have_text('Slow poetry in America : a poetry quarterly', count: 2)
      expect(page).to have_css('#appointmentRequestsAccordion li', count: 2)
      expect(page).to have_text('Medium poetry in America : a poetry quarterly', count: 2)
      expect(page).to have_css('#savedForLaterRequestsAccordion li', count: 2)

      click_button 'Save changes'
    end
    perform_enqueued_jobs

    within '#aeon_appointment_1' do
      expect(page).to have_text('Slow poetry in America')
      expect(page).to have_text('PR9195.1 .S56 NO.1')
      expect(page).to have_no_text('PR9195.1 .S56 NO.2')

      expect(page).to have_text('Medium poetry in America')
      expect(page).to have_text('assigned call number 2')
      expect(page).to have_no_text('assigned call number 1')
    end
  end
end
