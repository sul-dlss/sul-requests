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
    Aeon::Queue.new(id: 5, queue_name: 'Awaiting User Review', queue_type: 'Transaction')
  end
  let(:stub_aeon_client) do
    instance_double(AeonClient,
                    find_user: aeon_user,
                    appointments_for: [appointment],
                    find_queue: queue,
                    update_request: build(:aeon_request, transaction_number: 100),
                    update_request_route: build(:aeon_request, transaction_number: 100),
                    requests_for: [build(:aeon_request, transaction_number: 100, username: user.email_address, appointment_id: nil)],
                    cancel_appointment: [],
                    reading_rooms:,
                    activities_for: [],
                    available_appointments: [])
  end

  before do
    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    login_as(current_user)
    visit aeon_appointments_path
  end

  it 'updates the draft request appointment' do
    within '#draft_aeon_requests_sidebar' do
      click_on 'Appointment'
      click_on I18n.l(1.week.from_now, format: :date_only).to_s
    end

    within '#aeon_appointments' do
      expect(page).to have_text('Throwing a sinker ball at 94 mpg with wicked movement')
    end
    expect(stub_aeon_client).to have_received(:update_request).with({ aeon_payload: [{ op: 'replace', path: '/appointmentId', value: 23 },
                                                                                     { op: 'remove', path: '/forPublication' },
                                                                                     { op: 'remove', path: '/itemInfo5' },
                                                                                     { op: 'remove', path: '/specialRequest' },
                                                                                     { op: 'remove', path: '/requestFor' }],
                                                                      transaction_number: 100 })
  end
end
