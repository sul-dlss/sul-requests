# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Request Page' do
  let(:mock_client) { instance_double(FolioClient, ping: true) }
  let(:patron) do
    build(:sponsor_patron)
  end

  let(:service_points) do
    build(:service_points)
  end

  let(:api_response) { instance_double(Faraday::Response, status: 204) }

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive_messages(cancel_request: api_response,
                                           change_pickup_service_point: api_response,
                                           change_pickup_expiration: api_response)
    allow(Folio::Types).to receive_messages(service_points: Folio::TypeStore.new(Folio::ServicePoint, service_points))

    login_as(CurrentUser.new(username: 'stub_user', patron_key: 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1', shibboleth: true))
    allow(Folio::Patron).to receive(:find_by).with(patron_key: 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1').and_return(patron)
  end

  it 'has ready for pickup request data' do
    visit folio_requests_path

    within('#folio_request_7fa87cfe-df57-4dc7-953b-a5a44ff37d91') do
      expect(page).to have_text(/Rothko : the color field paintings/)
      expect(page).to have_text('Awaiting pick up at Green Library')
      expect(page).to have_text 'ND237 .R725 A4 2017 F'
    end
  end

  it 'ready for pickup can be cancelled' do
    visit folio_requests_path

    within('#folio_request_7fa87cfe-df57-4dc7-953b-a5a44ff37d91') do
      click_on 'Cancel'
    end

    expect(page).to have_css '.flash_messages', text: 'Success!'
  end

  it 'is editable' do
    visit edit_folio_request_path('7fa87cfe-df57-4dc7-953b-a5a44ff37d91')
    select('Engineering Library (Terman)', from: 'service_point')
    fill_in('not_needed_after', with: '1999/01/01')
    click_on 'Change'

    expect(page).to have_css 'div.alert-success', text: 'Success!', count: 2
  end

  it 'is sortable', :js do
    visit folio_requests_path

    within '#requests' do
      expect(page).to have_css('.dropdown-toggle', text: 'Sort by not needed after')
      click_on 'Sort by not needed after'

      within '[data-sortable-target="menu"] .dropdown-menu' do
        click_on 'title'
      end

      expect(page).to have_css('.dropdown-toggle', text: 'Sort by title')
      expect(page).to have_css('.active[data-sortable-sort-param="title"]', visible: :all)

      within(first('ul.requests li')) do
        expect(page).to have_text(/A history of Persia/)
      end
    end
  end
end
