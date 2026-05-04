# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Appointments', :js do
  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true) }
  let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }

  let(:requests) do
    [build(:aeon_request, title: 'title1', activity_id: 1, web_request_form: 'multiple'),
     build(:aeon_request, title: 'title2', activity_id: 5, web_request_form: 'multiple'),
     build(:aeon_request, title: 'title3', activity_id: 3, web_request_form: 'multiple')]
  end

  let(:queue) do
    Aeon::Queue.new(id: 8, queue_name: 'Awaiting Staff Review', queue_type: 'Transaction')
  end
  let(:stub_aeon_client) do
    instance_double(AeonClient,
                    find_user: aeon_user,
                    activities_for:,
                    find_queue: queue,
                    requests_for: requests)
  end

  let(:activities_for) do
    [
      instance_double(Aeon::Activity,
                      start_time: DateTime.new(2026, 2, 19, 12, 0, 0),
                      stop_time: DateTime.new(2026, 2, 19, 13, 0, 0),
                      name: 'Activity1',
                      activity_type: 'Class visit',
                      active?: true,
                      location: 'Special Collections',
                      sites: ['SPECUA'],
                      sort_key: DateTime.new(2026, 2, 19, 12, 0, 0),
                      requests: [],
                      reading_room: nil,
                      users: [aeon_user],
                      id: 1),
      instance_double(Aeon::Activity,
                      start_time: DateTime.new(2026, 2, 19, 12, 0, 0),
                      stop_time: DateTime.new(2026, 2, 19, 13, 0, 0),
                      sort_key: DateTime.new(2026, 2, 19, 12, 0, 0),
                      name: 'Activity2',
                      activity_type: 'Class visit',
                      active?: false,
                      location: 'Special Collections',
                      sites: ['SPECUA'],
                      requests: [],
                      reading_room: nil,
                      users: [aeon_user],
                      id: 2),
      instance_double(Aeon::Activity,
                      start_time: DateTime.new(2026, 4, 19, 12, 0, 0),
                      stop_time: DateTime.new(2026, 4, 19, 13, 0, 0),
                      name: 'Activity3',
                      activity_type: 'Class visit 2',
                      active?: true,
                      location: 'Special Collections',
                      sites: ['SPECUA'],
                      sort_key: DateTime.new(2026, 2, 19, 12, 0, 0),
                      requests: [],
                      reading_room: nil,
                      users: [aeon_user],
                      id: 3),
      instance_double(Aeon::Activity,
                      start_time: nil,
                      stop_time: nil,
                      name: 'Exhibit',
                      activity_type: 'Exhibit',
                      active?: true,
                      location: nil,
                      sites: %w[SPECUA EASTASIA],
                      sort_key: 100.years.from_now,
                      requests: [],
                      reading_room: nil,
                      users: [aeon_user],
                      id: 4)
    ]
  end

  before do
    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    login_as(current_user)
    visit aeon_activities_path
  end

  it 'displays all appointments' do
    expect(page).to have_css('h1', text: 'Activities')
    expect(page).to have_text(/Activity1.*Feb 19, 2026.*12:00 pm - 1:00 pm.*Special Collections/m)
    expect(page).to have_text(/Activity3.*Apr 19, 2026 12:00 pm - 1:00 pm Special Collections/m)
    expect(page).to have_text(/Exhibit/m)
    expect(page).to have_no_text('Activity2')

    expect(page).to have_text('title1', count: 1)
    expect(page).to have_no_text('title2')
    expect(page).to have_text('title3', count: 1)
    expect(page).to have_text('No items have been requested for this activity.', count: 1)
  end
end
