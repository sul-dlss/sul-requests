# frozen_string_literal: true

require 'rails_helper'

describe 'Status Page' do
  let(:request) { create(:mediated_page, user: user) }

  before do
    stub_current_user(user)
  end

  describe 'by webuath users' do
    let(:user) { create(:webauth_user) }

    it 'is available' do
      visit status_mediated_page_path(request)

      expect(page).to have_css('h1', text: 'Status of your request')
      expect(page).to have_css('h2', text: request.item_title)

      expect(page).to have_css('dt', text: 'Requested on')
      expect(page).to have_css('dt', text: 'Will be delivered to')
    end
  end

  describe 'by users with tokens' do
    let(:user) { create(:library_id_user) }

    it 'is available' do
      visit status_mediated_page_path(request, token: request.encrypted_token)

      expect(page).to have_css('h1', text: 'Status of your request')
      expect(page).to have_css('h2', text: request.item_title)

      expect(page).to have_css('dt', text: 'Requested on')
      expect(page).to have_css('dt', text: 'Will be delivered to')
    end
  end

  describe 'status page title contains item title' do
    let(:user) { create(:webauth_user) }

    it 'page' do
      my_req = create(:page, user: user)
      visit status_page_path(my_req)

      expect(page).to have_title('Request status: Title for Page 1234')
    end

    it 'mediated' do
      visit status_mediated_page_path(request)

      expect(page).to have_title('Request status: Title of MediatedPage 1234')
    end

    it 'hold/recall' do
      my_req = create(:hold_recall, user: user)
      visit status_hold_recall_path(my_req)

      expect(page).to have_title('Request status: Title of HoldRecall 1234')
    end

    it 'scan' do
      my_req = create(:scan, user: user)
      visit status_scan_path(my_req)

      expect(page).to have_title('Request status: Title for Scan 12345')
    end
  end
end
