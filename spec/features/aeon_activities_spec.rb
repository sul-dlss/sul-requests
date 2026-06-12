# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Activities', :js do
  use_stub_aeon_client

  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true) }
  let(:aeon_user) { StubAeonClient::User.create(username: user.email_address, authType: 'Default') }

  let(:requests) do
    [
      StubAeonClient::Request.create(
        requestFor: { type: 'Activity', reference: 1 },
        itemTitle: 'title1',
        username: aeon_user.username,
        webRequestForm: 'multiple',
        transactionStatus: 1
      ),
      StubAeonClient::Request.create(
        requestFor: { type: 'Activity', reference: 5 },
        itemTitle: 'title2',
        username: aeon_user.username,
        webRequestForm: 'multiple',
        transactionStatus: 1
      ),
      StubAeonClient::Request.create(
        requestFor: { type: 'Activity', reference: 3 },
        itemTitle: 'title3',
        username: aeon_user.username,
        webRequestForm: 'multiple',
        transactionStatus: 1
      )
    ]
  end

  let(:activities) do
    [
      StubAeonClient::Activity.create(
        beginDate: Time.zone.local(2026, 2, 19, 12, 0, 0).iso8601,
        endDate: Time.zone.local(2026, 2, 19, 13, 0, 0).iso8601,
        name: 'Activity1',
        activityType: 'Class visit',
        active: true,
        activityStatus: 'Pending',
        location: 'Special Collections',
        users: [aeon_user],
        id: 1
      ),
      StubAeonClient::Activity.create(
        beginDate: Time.zone.local(2026, 2, 19, 13, 0, 0).iso8601,
        endDate: Time.zone.local(2026, 2, 19, 14, 0, 0).iso8601,
        name: 'Activity2',
        activityType: 'Class visit',
        active: false,
        activityStatus: 'Pending',
        location: 'Special Collections',
        users: [aeon_user],
        id: 2
      ),
      StubAeonClient::Activity.create(
        beginDate: Time.zone.local(2026, 4, 19, 14, 0, 0).iso8601,
        endDate: Time.zone.local(2026, 4, 19, 15, 0, 0).iso8601,
        name: 'Activity3',
        activityType: 'Class visit 2',
        active: true,
        activityStatus: 'Pending',
        location: 'Special Collections',
        users: [aeon_user],
        id: 3
      ),
      StubAeonClient::Activity.create(
        beginDate: nil,
        endDate: nil,
        name: 'Exhibit',
        activityType: 'Exhibit',
        active: true,
        activityStatus: 'Pending',
        location: nil,
        users: [aeon_user],
        id: 4
      )
    ]
  end

  before do
    activities
    requests

    login_as(current_user)

    visit aeon_activities_path
  end

  it 'displays all appointments' do
    expect(page).to have_css('h1', text: 'Activities')
    expect(page).to have_text 'Activity1 Feb 19, 2026 12:00 pm - 1:00 pm Special Collections', normalize_ws: true
    expect(page).to have_text 'Activity3 Apr 19, 2026 2:00 pm - 3:00 pm Special Collections', normalize_ws: true
    expect(page).to have_text(/Exhibit/m)
    expect(page).to have_no_text('Activity2')

    expect(page).to have_text('title1', count: 1)
    expect(page).to have_no_text('title2')
    expect(page).to have_text('title3', count: 1)
    expect(page).to have_text('No items have been requested for this activity.', count: 1)
  end
end
