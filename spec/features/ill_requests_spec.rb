# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ILL Request Page' do
  let(:mock_client) { instance_double(FolioClient, ping: true) }
  let(:patron) do
    build(:sponsor_patron)
  end

  let(:illiad_requests) do
    [
      IlliadRequests::Request.new({
                                    'CreationDate' => '2024-01-01T00:00:00Z'
                                  })
    ]
  end

  before do
    login_as(CurrentUser.new(username: 'stub_user', patron_key: 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1', shibboleth: true))
    allow(Folio::Patron).to receive(:find_by).with(patron_key: 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1').and_return(patron)

    allow(patron).to receive_messages(illiad_requests: illiad_requests)
  end

  it 'has request data' do
    visit ill_requests_path

    expect(page).to have_css('.requests li', count: 1)
    expect(page).to have_css('li .status-pill', text: 'Pickup')
  end

  context 'with a scan request' do
    let(:illiad_requests) do
      [
        IlliadRequests::Request.new({
                                      'CreationDate' => '2024-01-01T00:00:00Z',
                                      'PhotoJournalTitle' => 'Some Journal'
                                    })
      ]
    end

    it 'has request data' do
      visit ill_requests_path

      expect(page).to have_css('.requests li', count: 1)
      expect(page).to have_css('li .status-pill', text: 'Digitization')
    end
  end
end
