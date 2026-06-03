# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Add items modal', :js do
  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true, patron_key: user.patron_key, ldap_attributes: {}) }
  let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }
  let(:reading_rooms) { JSON.load_file('spec/fixtures/reading_rooms.json').map { |room| Aeon::ReadingRoom.from_dynamic(room) } }
  let(:saved_for_later_request_one) do
    build(:aeon_request, call_number: 'PR9195.1 .S56 NO.1', title: 'Slow poetry in America : a poetry quarterly',
                         appointment_id: nil,
                         transaction_number: 100, username: aeon_user.username, web_request_form: 'multiple')
  end
  let(:saved_for_later_request_two) do
    build(:aeon_request, call_number: 'PR9195.1 .S56 NO.2', title: 'Slow poetry in America : a poetry quarterly',
                         appointment_id: nil,
                         transaction_number: 101, username: aeon_user.username, web_request_form: 'multiple')
  end
  let(:saved_for_later_request_three) do
    build(:aeon_request, call_number: 'PR8195.1 .S56 NO.2', title: 'Fast poetry in America : a poetry monthly',
                         transaction_number: 102, username: aeon_user.username, appointment_id: nil,
                         shipping_option: 'Electronic Delivery')
  end

  let(:submitted_request_one) do
    build(:aeon_request, call_number: 'assigned call number 1', title: 'Medium poetry in America : a poetry quarterly',
                         appointment_id: appointment.id,
                         transaction_number: 103, username: aeon_user.username, web_request_form: 'multiple')
  end

  let(:submitted_request_two) do
    build(:aeon_request, call_number: 'assigned call number 2', title: 'Medium poetry in America : a poetry quarterly',
                         appointment_id: appointment.id,
                         transaction_number: 104, username: aeon_user.username, web_request_form: 'multiple')
  end

  let(:saved_for_later_queue) do
    Aeon::Queue.new(id: 5, queue_name: 'Awaiting User Review', queue_type: 'Transaction')
  end

  let(:submitted_queue) { Aeon::Queue.new(id: 8, queue_name: 'Awaiting Staff Review', queue_type: 'Transaction') }

  let(:stub_aeon_client) do
    instance_double(AeonClient,
                    find_user: aeon_user,
                    find_queue: saved_for_later_queue,
                    appointments_for: [appointment],
                    requests_for: [draft_request_one, draft_request_two, draft_request_three, submitted_request_one, submitted_request_two],
                    reading_rooms:,
                    update_request_route: build(:aeon_request, transaction_number: 100),
                    activities_for: [],
                    available_appointments:)
  end

  let(:appointment) { build(:aeon_appointment, start_time: 1.week.from_now) }

  let(:available_appointments) do
    [instance_double(Aeon::AvailableAppointment,
                     start_time: DateTime.new(2026, 2, 19),
                     maximum_appointment_length: 210.minutes)]
  end

  before do
    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    allow(submitted_request_one).to receive_messages(transaction_queue: submitted_queue)
    allow(submitted_request_two).to receive_messages(transaction_queue: submitted_queue)
    allow(stub_aeon_client).to receive_messages(update_request: submitted_request_two)
    allow(aeon_user).to receive_messages(requests: [draft_request_one, draft_request_two, draft_request_three, submitted_request_one,
                                                    submitted_request_two])
    login_as(current_user)
    visit aeon_appointments_path
  end

  it 'opens and submits add items' do # rubocop:disable RSpec/ExampleLength
    click_link 'Add items'
    within '.modal' do
      expect(page).to have_no_text('Fast poetry in America : a poetry quarterly')
      click_on 'Items scheduled to use during this appointment'

      expect(page).to have_text('Slow poetry in America : a poetry quarterly', count: 1)
      expect(page).to have_css('#appointmentRequestsAccordion li', count: 2)
      expect(page).to have_text('Medium poetry in America : a poetry quarterly', count: 1)
      expect(page).to have_css('#savedForLaterRequestsAccordion li', count: 2)

      # Add slow poetry call number 1 to scheduled appointments
      find("button[data-transaction-number='#{draft_request_one.id}']").click

      # expect a header to move into modal
      expect(page).to have_text('Slow poetry in America : a poetry quarterly', count: 2)
      expect(page).to have_css('#appointmentRequestsAccordion li', count: 3)
      expect(page).to have_text('Medium poetry in America : a poetry quarterly', count: 1)
      expect(page).to have_css('#savedForLaterRequestsAccordion li', count: 1)

      # Add slow poetry call number 2 to scheduled appointments
      find("button[data-transaction-number='#{draft_request_two.id}']").click

      expect(page).to have_text('Slow poetry in America : a poetry quarterly', count: 1)
      expect(page).to have_css('#appointmentRequestsAccordion li', count: 4)
      expect(page).to have_text('Medium poetry in America : a poetry quarterly', count: 1)
      expect(page).to have_css('#savedForLaterRequestsAccordion li', count: 0)

      # Remove scheduled appointment and draft appointment
      find("button[data-transaction-number='#{submitted_request_one.id}']").click
      find("button[data-transaction-number='#{draft_request_two.id}']").click

      expect(page).to have_text('Slow poetry in America : a poetry quarterly', count: 2)
      expect(page).to have_css('#appointmentRequestsAccordion li', count: 2)
      expect(page).to have_text('Medium poetry in America : a poetry quarterly', count: 2)
      expect(page).to have_css('#savedForLaterRequestsAccordion li', count: 2)

      click_button 'Save changes'
    end
    perform_enqueued_jobs

    sleep 0.5
    expect(stub_aeon_client).to have_received(:update_request).with(
      { transaction_number: 100, aeon_payload:
                                            [{ op: 'replace', path: '/appointmentId', value: 23 },
                                             { op: 'remove',
                                               path: '/forPublication' },
                                             { op: 'remove',
                                               path: '/itemInfo5' },

                                             { op: 'remove',
                                               path: '/specialRequest' },
                                             { op: 'remove',
                                               path: '/requestFor' }] }
    )

    expect(stub_aeon_client).to have_received(:update_request).with(
      { transaction_number: 103, aeon_payload:
     [{ op: 'remove', path: '/appointmentId' },
      { op: 'remove',
        path: '/forPublication' },
      { op: 'remove',
        path: '/itemInfo5' },
      { op: 'remove',
        path: '/specialRequest' },

      { op: 'remove',
        path: '/requestFor' }] }
    )
  end
end
