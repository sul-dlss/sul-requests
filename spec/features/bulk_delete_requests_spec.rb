# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk delete actions and modal', :js do
  use_stub_aeon_client

  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true) }
  let(:aeon_user) { StubAeonClient::User.create(username: user.email_address, authType: 'Default') }
  let(:first_request) do
    StubAeonClient::Request.create(
      id: 100,
      callNumber: 'PR9195.1 .S56 NO.1',
      itemTitle: 'Slow poetry in America : a poetry quarterly',
      username: aeon_user.username,
      webRequestForm: 'multiple',
      site: 'SPECUA'
    )
  end
  let(:second_request) do
    StubAeonClient::Request.create(
      id: 101,
      callNumber: 'PR9195.1 .S56 NO.2',
      itemTitle: 'Slow poetry in America : a poetry quarterly',
      username: aeon_user.username,
      webRequestForm: 'multiple',
      site: 'SPECUA'
    )
  end
  let(:third_request) do
    StubAeonClient::Request.create(
      id: 102,
      callNumber: 'PR9195.1 .S56 NO.1',
      itemTitle: 'Fast poetry in America : a poetry monthly',
      username: aeon_user.username,
      shippingOption: 'Electronic Delivery',
      webRequestForm: 'multiple',
      site: 'SPECUA'
    )
  end

  before do
    [first_request, second_request, third_request]
    login_as(current_user)
    visit aeon_requests_path(kind: 'saved_for_later')
  end

  describe 'on page load' do
    it 'display delete checkboxes next to each request and a delete all input' do
      expect(page).to have_css('input[data-request-bulk-delete-target="select"]', count: 3)
      expect(page).to have_css('input[data-request-bulk-delete-target="selectall"]', count: 1)
    end
  end

  describe 'when selecting a single request' do
    it 'shows details of the selected requests in the bulk delete modal' do
      expect(page).to have_button('delete-all', disabled: true)

      check('delete-bulk-100')
      expect(page).to have_button('delete-all', disabled: false)

      click_button('delete-all')
      expect(page).to have_css('.modal-title', text: 'Delete 1 request?')
      expect(page).to have_css('.modal-body', text: 'Slow poetry in America : a poetry quarterly')
    end
  end

  describe 'when selecting two requests' do
    it 'shows descriptions grouped by type and title' do
      check('delete-bulk-100')
      check('delete-bulk-101')

      click_button('delete-all')
      expect(page).to have_css('.modal-title', text: 'Delete 2 requests?')
      expect(page).to have_css('.modal-body', text: 'Reading room use', count: 1)
      expect(page).to have_css('.modal-body', text: 'Slow poetry in America : a poetry quarterly', count: 1)
      expect(page.find('.modal-body')).to have_text('PR9195.1 .S56 NO.1').and have_text('PR9195.1 .S56 NO.2')
    end
  end

  describe 'when selecting all requests' do
    it 'shows a summary description in the modal when all items are selected' do
      check('select-all-delete')
      expect(page).to have_css('input[data-request-bulk-delete-target="select"]:checked', count: 3)
      expect(page).to have_button('delete-all')

      click_button('delete-all')
      expect(page).to have_css('.modal-title', text: 'Delete all requests?')
      expect(page).to have_css('.modal-body', text: '1 digitization and 2 reading room use requests')
    end
  end
end
