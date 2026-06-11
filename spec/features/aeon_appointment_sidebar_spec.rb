# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Appointments', :js do
  use_stub_aeon_client

  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true) }

  let(:aeon_user) { StubAeonClient::User.create(username: user.email_address, authType: 'Default') }
  let(:appointment) do
    create(:remote_aeon_appointment, username: aeon_user.username, reading_room:, startTime: 1.week.from_now,
                                     stopTime: 1.week.from_now + 1.hour)
  end
  let(:reading_room) { StubAeonClient::ReadingRoom.find_by(name: 'Field Reading Room') }

  before do
    appointment

    StubAeonClient::Request.create!(
      itemTitle: 'Throwing a sinker ball at 94 mpg with wicked movement',
      username: aeon_user.username,
      webRequestForm: 'single',
      site: 'SPECUA'
    )

    login_as(current_user)
    visit aeon_appointments_path
  end

  it 'updates the saved for later request appointment' do
    within '#saved_for_later_aeon_requests_sidebar' do
      click_on 'Appointment'
      click_on I18n.l(1.week.from_now, format: :date_only).to_s
    end

    within '#aeon_appointments' do
      expect(page).to have_text('Throwing a sinker ball at 94 mpg with wicked movement')
    end
  end
end
