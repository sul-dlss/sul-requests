# frozen_string_literal: true

require 'rails_helper'
require 'active_support'
require 'active_support/testing/time_helpers'

RSpec.describe 'Proxy User' do
  include ActiveSupport::Testing::TimeHelpers

  let(:mock_client) { instance_double(FolioClient, ping: true, find_effective_loan_policy: {}) }

  let(:patron) do
    build(:proxy_patron)
  end

  let(:sponsor) do
    build(:sponsor_patron)
  end

  before do
    # NOTE: tests that rely on LoanPolicy#due_date_after_renewal have to
    #       take place when Time.now is included in the fixture's
    #       loan policy schedule date range.
    travel_to Time.zone.parse('2023-06-13T07:00:00.000+00:00')
    allow(Settings.features).to receive_messages(requests_redesign: true)

    allow(FolioClient).to receive(:new) { mock_client }
    allow(Folio::LoanPolicy).to receive(:new).and_return(build(:grad_mono_loans))

    allow(Folio::Patron).to receive(:find_by).with(patron_key: patron.key).and_return(patron)
    allow(mock_client).to receive(:extended_user_info).with(sponsor.key).and_return(sponsor.send(:extended_user_info))
    allow(mock_client).to receive(:extended_patron_info).with(sponsor.key).and_return(sponsor.send(:patron_graphql_response))

    login_as(CurrentUser.new(username: 'stub_user', patron_key: patron.key, shibboleth: true))
  end

  it 'has a control to switch between user and group', :js do
    visit root_path

    expect(page).to have_text('Personal Piper Proxy', normalize_ws: true)
    click_on 'Switch to proxy'
    click_on 'Proxy for: Shea Sponsor'
    expect(page).to have_text('On behalf of Shea Sponsor (sponsor)')

    click_on 'Switch to personal'
    click_on 'Personal account'

    expect(page).to have_text('Personal Piper Proxy', normalize_ws: true)
  end
end
