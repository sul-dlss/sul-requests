# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk delete actions and modal', :js do
  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true, patron_key: user.patron_key, ldap_attributes: {}) }
  let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }
  let(:first_request) do
    build(:aeon_request, call_number: 'PR9195.1 .S56 NO.1', title: 'Slow poetry in America : a poetry quarterly',
                         transaction_number: 100, username: aeon_user.username)
  end
  let(:second_request) do
    build(:aeon_request, call_number: 'PR9195.1 .S56 NO.2', title: 'Slow poetry in America : a poetry quarterly',
                         transaction_number: 101, username: aeon_user.username)
  end
  let(:draft_queue) do
    Aeon::Queue.new(id: 5, queue_name: 'Awaiting User Review', queue_type: 'Transaction')
  end
  let(:stub_aeon_client) do
    instance_double(AeonClient,
                    find_user: aeon_user,
                    find_queue: draft_queue,
                    appointments_for: [],
                    requests_for: [first_request, second_request],
                    reading_rooms: [],
                    available_appointments: [])
  end

  before do
    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    allow(aeon_user).to receive_messages(requests: [first_request, second_request])
    login_as(current_user)
    visit draft_aeon_requests_path
  end

  describe 'on page load' do
    it 'display delete checkboxes next to each request and a delete all input' do
      expect(page).to have_css('input[data-draft-request-target="select"]', count: 2)
      expect(page).to have_css('input[data-draft-request-target="selectall"]', count: 1)
    end
  end

  describe 'when selecting a single request' do
    it 'shows details of the selected requests in the bulk delete modal' do
      expect(page).to have_button('delete-all', disabled: true)

      check('delete-bulk-100')
      expect(page).to have_button('delete-all', disabled: false)

      click_button('delete-all')
      expect(page).to have_css('.modal-title', text: 'Delete 1 draft request?')
      expect(page).to have_css('.modal-body #request-content', text: 'Slow poetry in America : a poetry quarterly')
    end
  end

  describe 'when selecting all requests' do
    it 'shows a summary description in the modal when all items are selected' do
      check('select-all-delete')
      expect(page).to have_css('input[data-draft-request-target="select"]:checked', count: 2)
      expect(page).to have_button('delete-all')

      click_button('delete-all')
      expect(page).to have_css('.modal-title', text: 'Delete 2 draft requests?')
      expect(page).to have_css('.modal-body #request-content', text: '0 digitization and 2 reading room use requests')
    end
  end
end
