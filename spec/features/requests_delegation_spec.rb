# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Requests Delegation' do
  let(:selected_items) do
    [
      double(:item, barcode: '34567890', type: 'STKS', callnumber: 'ABC 123', checked_out?: false, processing?: false, missing?: false,
                    hold?: false, on_order?: false, hold_recallable?: false)
    ]
  end

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:fetch).and_return(double(:bib_data, title: 'Test title',
                                                                                              request_holdings: selected_items))
  end

  describe 'non-scannable materials' do
    it 'is automatically delegated to the page request form' do
      visit new_request_path(item_id: '12345', origin: 'SAL1/2', origin_location: 'STACKS')

      expect(page).to have_css('h1#dialogTitle', text: 'Request & pickup service')
      expect(current_url).to eq new_page_url(item_id: '12345', origin: 'SAL1/2', origin_location: 'STACKS')
    end
  end

  describe 'mediated page materials' do
    it 'automatically delegate to the mediated page request form' do
      visit new_request_path(item_id: '12345', origin: 'ART', origin_location: 'ARTLCKL')

      expect(page).to have_css('h1#dialogTitle', text: 'Request on-site access')
      expect(current_url).to eq new_mediated_page_url(item_id: '12345', origin: 'ART', origin_location: 'ARTLCKL')
    end
  end

  describe 'scannable materials' do
    it 'is given the opportunity to request a scan or delivery' do
      visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_css('h1#dialogTitle', text: 'Request options')

      within('#scan-or-deliver') do
        expect(page).to have_css('a', text: 'Request & pickup')
        expect(page).to have_css('a', text: 'Scan to PDF')
      end
    end
  end

  describe 'scannable only material' do
    let(:selected_items) do
      [
        double(:item, barcode: '34567890', type: 'NONCIRC', callnumber: 'ABC 123', hold_recallable?: false, checked_out?: false,
                      processing?: false, missing?: false)
      ]
    end

    it 'disables the link to page the item' do
      visit new_request_path(item_id: '12345', origin: 'SAL', origin_location: 'SAL-TEMP')

      within('#scan-or-deliver') do
        expect(page).to have_css('a.disabled', text: 'Request & pickup')
        expect(page).to have_content('This item is for in-library use and not available for Request & pickup.')
      end
    end
  end
end
