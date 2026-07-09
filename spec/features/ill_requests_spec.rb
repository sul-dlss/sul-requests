# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ILL Request Page' do
  let(:mock_client) { instance_double(FolioClient, ping: true) }
  let(:patron) do
    build(:sponsor_patron)
  end

  let(:illiad_requests) do
    [
      Illiad::Request.new({
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
        Illiad::Request.new({
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

  describe 'creating a new request' do
    before do
      allow(IlliadClient).to receive(:new).and_return(mock_ill_client)
    end

    let(:mock_ill_client) do
      instance_double(IlliadClient, create: true)
    end

    it 'submits the request to ILLiad' do
      visit new_ill_request_path

      fill_in 'Title', with: 'Test Title'
      fill_in 'Author', with: 'Test Author'
      fill_in 'Link', with: 'AI told me this exists'
      fill_in 'Date of publication', with: '2032'
      fill_in 'ISBN', with: '1234567890'

      click_button 'Submit request'

      expect(page).to have_text('Your request has been submitted to Interlibrary Loan.')
      expect(mock_ill_client).to have_received(:create).with(hash_including(
                                                               'LoanTitle' => 'Test Title',
                                                               'LoanAuthor' => 'Test Author',
                                                               'CitedIn' => 'AI told me this exists',
                                                               'LoanDate' => '2032',
                                                               'ISSN' => '1234567890'
                                                             ))
    end
  end
end
