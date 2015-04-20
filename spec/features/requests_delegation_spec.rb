require 'rails_helper'

describe 'Requests Delegation' do
  describe 'non-scannable materials' do
    it 'should be automatically delegated to the page request form' do
      visit new_request_path(item_id: '12345', origin: 'SAL1/2', origin_location: 'STACKS')

      expect(page).to have_css('h1#dialogTitle', text: 'Request delivery to campus library')
      expect(current_url).to eq new_page_url(item_id: '12345', origin: 'SAL1/2', origin_location: 'STACKS')
    end
  end
  describe 'scannable materials' do
    it 'should be given the opportunity to request a scan or delivery' do
      visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_css('h1#dialogTitle', text: 'Request')

      within('#scan-or-deliver') do
        expect(page).to have_css('a', text: 'Deliver to campus library')
        expect(page).to have_css('a', text: /Scan to PDF.*requires SUNet login/)
      end
    end
  end
end
