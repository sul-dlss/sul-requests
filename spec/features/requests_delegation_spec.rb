# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Requests Delegation' do
  describe 'non-requestable materials' do
    it 'is automatically delegated to the page request form' do
      skip('All searchworks items are pageable') if Settings.ils.bib_model == 'SearchworksItem'

      stub_bib_data_json(build(:green_holdings))

      expect do
        visit new_request_path(item_id: '12345', origin: 'GREEN', origin_location: 'STACKS')
      end.to raise_error(PagesController::UnpageableItemError)
    end
  end

  describe 'non-scannable materials' do
    it 'is automatically delegated to the page request form' do
      stub_bib_data_json(build(:page_lp_holdings))
      visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'PAGE-LP')

      expect(page).to have_css('h1#dialogTitle', text: 'Request & pickup service')
      expect(current_url).to eq new_page_url(item_id: '12345', origin: 'SAL3', origin_location: 'PAGE-LP')
    end
  end

  describe 'mediated page materials' do
    it 'automatically delegate to the mediated page request form' do
      stub_bib_data_json(build(:single_mediated_holding))
      visit new_request_path(item_id: '12345', origin: 'ART', origin_location: 'ARTLCKL')

      expect(page).to have_css('h1#dialogTitle', text: 'Request on-site access')
      expect(current_url).to eq new_mediated_page_url(item_id: '12345', origin: 'ART', origin_location: 'ARTLCKL')
    end
  end

  describe 'scannable materials' do
    it 'is given the opportunity to request a scan or delivery' do
      stub_bib_data_json(build(:scannable_holdings))
      visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_css('h1#dialogTitle', text: 'Request options')

      within('#scan-or-deliver') do
        expect(page).to have_css('a', text: 'Request & pickup')
        expect(page).to have_css('a', text: 'Scan to PDF')
      end
    end
  end

  describe 'scannable only material' do
    it 'disables the link to page the item' do
      pending('FOLIO does not have any non-circulating, scannable items') if Settings.ils.bib_model == 'Folio::Instance'
      stub_bib_data_json(build(:scannable_only_holdings))
      visit new_request_path(item_id: '12345', origin: 'SAL', origin_location: 'SAL-TEMP')

      within('#scan-or-deliver') do
        expect(page).to have_css('a.disabled', text: 'Request & pickup')
        expect(page).to have_content('This item is for in-library use and not available for Request & pickup.')
      end
    end
  end
end
