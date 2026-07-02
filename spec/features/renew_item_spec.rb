# frozen_string_literal: true

require 'rails_helper'
require 'active_support'
require 'active_support/testing/time_helpers'

RSpec.describe 'Renew item', :js do
  include ActiveSupport::Testing::TimeHelpers

  let(:mock_client) { instance_double(FolioClient, ping: true, find_effective_loan_policy: {}) }
  let(:patron) do
    build(:sponsor_patron)
  end

  let(:service_points) do
    build(:service_points)
  end

  let(:api_response) { instance_double(FolioClient::RenewCheckoutResponse, success?: true, checkout: patron.checkouts.first, updated_checkout: updated_checkout) }
  let(:updated_checkout) { patron.checkouts.first.update('dueDate' => 2.years.from_now.iso8601) }

  before do
    # NOTE: tests that rely on LoanPolicy#due_date_after_renewal have to
    #       take place when Time.now is included in the fixture's
    #       loan policy schedule date range.
    travel_to Time.zone.parse('2023-06-13T07:00:00.000+00:00')
    allow(FolioClient).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive_messages(renew_checkout: api_response)
    allow(Folio::Types).to receive_messages(service_points: Folio::TypeStore.new(Folio::ServicePoint, service_points))
    allow(Folio::LoanPolicy).to receive(:new).and_return(build(:grad_mono_loans))

    patron.checkouts.each do |checkout|
      allow(checkout).to receive(:loan_policy).and_return(build(:grad_mono_loans))
    end

    login_as(CurrentUser.new(username: 'stub_user', patron_key: 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1', shibboleth: true))
    allow(Folio::Patron).to receive(:find_by).with(patron_key: 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1').and_return(patron)

    allow(Settings.features).to receive(:requests_redesign).and_return(true)
  end

  it 'enabled through checkout page' do
    visit checkouts_path

    within(first('ul.checkouts-list li')) do
      click_on 'Renew'
    end

    expect(page).to have_button('Nothing is eligible to renew', disabled: true)
    expect(page).to have_text 'Renewed until: Jun 13, 2025'
  end

  it 'has a button to renew all items' do
    visit checkouts_path

    click_on 'Renew eligible items (1)'

    expect(page).to have_button('Nothing is eligible to renew', disabled: true)
    expect(page).to have_text 'Renewed until: Jun 13, 2025'
    expect(page).to have_css '.flash_messages', text: 'Successfully renewed 1 item'
  end
end
