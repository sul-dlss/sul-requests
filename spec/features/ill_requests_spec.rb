# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ILL Request Page', :js do
  let(:mock_client) { instance_double(FolioClient, ping: true) }
  let(:patron) do
    build(:sponsor_patron)
  end

  let(:illiad_requests) do
    [
      Illiad::Request.new({
                            'CreationDate' => '2024-01-01T00:00:00Z',
                            'TransactionNumber' => '1',
                            'LoanTitle' => 'Pickup title',
                            'CitedIn' => 'Link',
                            'ItemInfo4' => 'GREEN'
                          })
    ]
  end

  def wait_for_email
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.1 until ActionMailer::Base.deliveries.count >= 1
    end
  end

  before do
    login_as(CurrentUser.new(username: 'stub_user', patron_key: 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1', shibboleth: true))
    allow(Folio::Patron).to receive(:find_by).with(patron_key: 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1').and_return(patron)

    allow(patron).to receive_messages(illiad_requests: illiad_requests)
  end

  context 'with pickup request' do
    it 'has request data' do
      visit ill_requests_path

      expect(page).to have_css('.requests li', count: 1)
      expect(page).to have_css('li .status-pill', text: 'Pickup')
    end

    it 'can edit the request' do
      visit ill_requests_path
      click_link 'Edit Pickup title'
      expect(page).to have_text 'Edit request'
      select 'Music Library', from: 'Deliver to'
      click_button 'Save'
      wait_for_email
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include('illiad-test@stanford.edu')
      expect(mail.cc).to include('superuser1@stanford.edu')
      expect(mail.subject).to eq('ILLiad request update, please remediate')
      expect(mail.body).to have_text('Previously requested item info4: GREEN-LOAN')
      expect(mail.body).to have_text('New request item info4: MUSIC')
      expect(mail.body).to have_no_text('New request not wanted after')
    end
  end

  context 'with a scan request' do
    let(:illiad_requests) do
      [
        Illiad::Request.new({
                              'CreationDate' => '2024-01-01T00:00:00Z',
                              'PhotoJournalTitle' => 'Some Journal',
                              'TransactionNumber' => '2',
                              'PhotoArticleTitle' => 'photo article title',
                              'CitedIn' => 'https://searchworks.stanford.edu/view/instance_hrid'
                            })
      ]
    end
    let(:mock_ill_client) { instance_double(IlliadClient, update_request_route: illiad_requests.first) }

    before do
      allow(IlliadClient).to receive(:new).and_return(mock_ill_client)
    end

    it 'has request data' do
      visit ill_requests_path

      expect(page).to have_css('.requests li', count: 1)
      expect(page).to have_css('li .status-pill', text: 'Digitization')
    end

    it 'can delete the request' do
      visit ill_requests_path
      click_button 'Delete Some Journal'
      expect(page).to have_text 'Delete request?'
      click_button 'Yes - Delete'
      expect(page).to have_css('.requests li', count: 0)
    end

    it 'can edit the request' do
      visit ill_requests_path
      click_link 'Edit Some Journal'
      expect(page).to have_text 'Edit request'
      fill_in 'Page range', with: '1-2'
      fill_in 'Title', with: 'New Journal update'
      click_button 'Save'
      wait_for_email
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include('illiad-test@stanford.edu')
      expect(mail.cc).to include('superuser1@stanford.edu')
      expect(mail.subject).to eq('ILLiad request update, please remediate')
      expect(mail.body).to have_text('Previously requested photo journal inclusive pages:')
      expect(mail.body).to have_text('New request photo journal inclusive pages: 1-2')
      expect(mail.body).to have_text('Previously requested photo article title: photo article title')
      expect(mail.body).to have_text('New request photo article title: New Journal update')
    end
  end

  describe 'creating a new request', :js do
    before do
      allow(IlliadClient).to receive(:new).and_return(mock_ill_client)
    end

    let(:mock_ill_client) do
      instance_double(IlliadClient, create: true)
    end

    it 'submits the request to ILLiad' do
      visit new_ill_request_path

      choose 'Pickup physical item'
      click_on 'Continue'

      fill_in 'Title', with: 'Test Title'
      fill_in 'Author', with: 'Test Author'
      fill_in 'Link', with: 'AI told me this exists'
      fill_in 'Date of publication', with: '2032'
      fill_in 'ISBN', with: '1234567890'

      click_on 'Continue'

      click_button 'Submit request'

      expect(page).to have_text('Your request has been submitted to Interlibrary Loan.')
      expect(mock_ill_client).to have_received(:create).with(an_object_having_attributes(
                                                               loan_title: 'Test Title',
                                                               loan_author: 'Test Author',
                                                               cited_in: 'AI told me this exists',
                                                               loan_date: '2032',
                                                               issn: '1234567890'
                                                             ))
    end
  end
end
