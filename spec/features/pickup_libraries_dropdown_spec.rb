# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pickup Libraries Dropdown' do
  let(:standard_pickup_lib_total) { Settings.default_pickup_libraries.count }

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:new).and_return(double(:bib_data, title: 'Test title', request_holdings: []))
  end

  describe 'for multiple libraries' do
    it 'has a select dropdown to choose the library to deliver to' do
      visit new_request_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      expect(page).to have_select('Deliver to')

      expect(page).to have_css('#request_destination option', count: standard_pickup_lib_total)
    end

    it 'simplfies the display of the text of the destination library if there is only one possible' do
      visit new_request_path(item_id: '1234', origin: 'ARS', origin_location: 'STACKS')

      expect(page).not_to have_css('select')

      expect(page).to have_css('.form-group .control-label', text: 'Will be delivered to')
      expect(page).to have_css('.form-group .input-like-text', text: 'Archive of Recorded Sound')
    end
  end

  describe 'libraries that should include themself in the pickup list' do
    context 'a standard library' do
      it 'does not include the configured library in the drop down' do
        visit new_request_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

        expect(page).to have_css('#request_destination option', count: standard_pickup_lib_total)
        expect(page).not_to have_css('option', text: 'Media Microtext')
      end
    end

    context 'libraries that are configured' do
      it 'appear in the drop down' do
        visit new_request_path(item_id: '1234', origin: 'MEDIA-MTXT', origin_location: 'MM-STACKS')

        expect(page).to have_css('#request_destination option', count: standard_pickup_lib_total + 1)
        expect(page).to have_css('option', text: 'Media Microtext')
      end
    end
  end
end
