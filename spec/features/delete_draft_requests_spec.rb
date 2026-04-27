# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk delete actions and modal', :js do
  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true, patron_key: user.patron_key, ldap_attributes: {}) }
  let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }
  let(:reading_rooms) { JSON.load_file('spec/fixtures/reading_rooms.json').map { |room| Aeon::ReadingRoom.from_dynamic(room) } }
  let(:first_request) do
    build(:aeon_request, call_number: 'PR9195.1 .S56 NO.1', title: 'Slow poetry in America : a poetry quarterly',
                         transaction_number: 100, username: aeon_user.username, web_request_form: 'multiple')
  end
  let(:second_request) do
    build(:aeon_request, call_number: 'PR9195.1 .S56 NO.2', title: 'Slow poetry in America : a poetry quarterly',
                         transaction_number: 101, username: aeon_user.username, web_request_form: 'multiple')
  end
  let(:third_request) do
    build(:aeon_request, call_number: 'PR8195.1 .S56 NO.2', title: 'Fast poetry in America : a poetry monthly',
                         transaction_number: 102, username: aeon_user.username,
                         shipping_option: 'Electronic Delivery')
  end
  let(:draft_queue) do
    Aeon::Queue.new(id: 5, queue_name: 'Awaiting User Review', queue_type: 'Transaction')
  end
  let(:stub_aeon_client) do
    instance_double(AeonClient,
                    find_user: aeon_user,
                    find_queue: draft_queue,
                    appointments_for: [],
                    requests_for: [first_request, second_request, third_request],
                    reading_rooms:,
                    available_appointments: [])
  end

  before do
    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    allow(aeon_user).to receive_messages(requests: [first_request, second_request, third_request])
    login_as(current_user)
    visit aeon_requests_path(kind: 'drafts')
  end

  describe 'on page load' do
    it 'display delete checkboxes next to each request and a delete all input' do
      expect(page).to have_css('input[data-draft-request-target="select"]', count: 3)
      expect(page).to have_css('input[data-draft-request-target="selectall"]', count: 1)
    end
  end

  describe 'when selecting a single request' do
    it 'shows details of the selected requests in the bulk delete modal' do
      expect(page).to have_button('delete-all', disabled: true)

      check('delete-bulk-100')
      expect(page).to have_button('delete-all', disabled: false)

      click_button('delete-all')
      expect(page).to have_css('.modal-title', text: 'Delete 1 saved for later request?')
      expect(page).to have_css('.modal-body', text: 'Slow poetry in America : a poetry quarterly')
    end
  end

  describe 'when selecting two requests' do
    it 'shows descriptions grouped by type and title' do
      check('delete-bulk-100')
      check('delete-bulk-101')

      click_button('delete-all')
      expect(page).to have_css('.modal-title', text: 'Delete 2 saved for later requests?')
      expect(page).to have_css('.modal-body', text: 'Reading room use', count: 1)
      expect(page).to have_css('.modal-body', text: 'Slow poetry in America : a poetry quarterly', count: 1)
      expect(page.find('.modal-body')).to have_content('PR9195.1 .S56 NO.1').and have_content('PR9195.1 .S56 NO.2')
    end
  end

  describe 'when selecting all requests' do
    it 'shows a summary description in the modal when all items are selected' do
      check('select-all-delete')
      expect(page).to have_css('input[data-draft-request-target="select"]:checked', count: 3)
      expect(page).to have_button('delete-all')

      click_button('delete-all')
      expect(page).to have_css('.modal-title', text: 'Delete 3 saved for later requests?')
      expect(page).to have_css('.modal-body', text: '1 digitization and 2 reading room use requests')
    end
  end
end
