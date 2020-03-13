# frozen_string_literal: true

require 'rails_helper'

describe 'Requests Delegation' do
  pending 'non-scannable materials' do
    it 'is automatically delegated to the page request form' do
      visit new_request_path(item_id: '12345', origin: 'SAL1/2', origin_location: 'STACKS')

      expect(page).to have_css('h1#dialogTitle', text: 'Request delivery to campus library')
      expect(current_url).to eq new_page_url(item_id: '12345', origin: 'SAL1/2', origin_location: 'STACKS')
    end
  end

  pending 'mediated page materials' do
    it 'automaticallies delegate to the mediated page request form' do
      visit new_request_path(item_id: '12345', origin: 'SPEC-COLL', origin_location: 'STACKS')

      expect(page).to have_css('h1#dialogTitle', text: 'Request on-site access')
      expect(current_url).to eq new_mediated_page_url(item_id: '12345', origin: 'SPEC-COLL', origin_location: 'STACKS')
    end
  end

  pending 'scannable materials' do
    before do
      stub_searchworks_api_json(build(:sal3_holdings))
    end

    it 'is given the opportunity to request a scan or delivery' do
      visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_css('h1#dialogTitle', text: 'Request')
      expect(page).to have_css('h2', text: 'SAL3 Item Title')

      within('#scan-or-deliver') do
        expect(page).to have_css('a', text: 'Deliver to campus library')
        expect(page).to have_css('a', text: /Scan to PDF.*requires SUNet login/)
      end
    end
  end
end
