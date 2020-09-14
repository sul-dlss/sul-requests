# frozen_string_literal: true

require 'rails_helper'

describe 'Requests Delegation' do
  describe 'non-scannable materials' do
    it 'is automatically delegated to the page request form' do
      visit new_request_path(item_id: '12345', origin: 'SAL1/2', origin_location: 'STACKS')

      expect(page).to have_css('h1#dialogTitle', text: 'Request & pickup service')
      expect(current_url).to eq new_page_url(item_id: '12345', origin: 'SAL1/2', origin_location: 'STACKS')
    end
  end

  describe 'mediated page materials' do
    it 'automaticallies delegate to the mediated page request form' do
      visit new_request_path(item_id: '12345', origin: 'SPEC-COLL', origin_location: 'STACKS')

      expect(page).to have_css('h1#dialogTitle', text: 'Request on-site access')
      expect(current_url).to eq new_mediated_page_url(item_id: '12345', origin: 'SPEC-COLL', origin_location: 'STACKS')
    end
  end

  describe 'scannable materials' do
    it 'is given the opportunity to request a scan or delivery' do
      stub_searchworks_api_json(build(:sal3_holdings))

      visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_css('h1#dialogTitle', text: 'Request options')

      within('#scan-or-deliver') do
        expect(page).to have_css('a', text: 'Request & pickup')
        expect(page).to have_css('a', text: 'Scan to PDF')
      end
    end

    context 'when an item is avaialble via temporary access' do
      before { stub_searchworks_api_json(build(:temporary_access_holdings)) }

      it 'disables the request option' do
        visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

        expect(page).to have_css('h1#dialogTitle', text: 'Request options')

        within('#scan-or-deliver') do
          expect(page).to have_css('a.disabled', text: 'Request & pickup')
          expect(page).to have_content('The physical copy is not available for Request & pickup.')
        end
      end
    end
  end

  describe 'scannable only material' do
    before { stub_searchworks_api_json(build(:scannable_only_holdings)) }

    it 'disables the link to page the item' do
      visit new_request_path(item_id: '12345', origin: 'SAL', origin_location: 'SAL-TEMP')

      within('#scan-or-deliver') do
        expect(page).to have_css('a.disabled', text: 'Request & pickup')
        expect(page).to have_content('This item is for in-library use and not available for Request & pickup.')
      end
    end
  end
end
