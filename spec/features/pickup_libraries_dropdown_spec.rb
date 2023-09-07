# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pickup Libraries Dropdown' do
  let(:standard_pickup_lib_total) { Folio::Types.service_points.where(is_default_pickup: true).length }
  let(:media_label) { 'Media Center' }

  let(:item) do
    build(:item,
          barcode: '3610512345678',
          callnumber: 'ABC 123',
          effective_location: build(:location, code: 'SAL3-STACKS'))
  end

  let(:instance) { instance_double(Folio::Instance, title: 'Test title', request_holdings: [item], items: []) }

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:fetch).and_return(instance)
  end

  describe 'for multiple libraries' do
    it 'has a select dropdown to choose the library to deliver to' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_select('Deliver to')

      expect(page).to have_css('#request_destination option', count: standard_pickup_lib_total)
    end

    context 'for a PAGE-EN location' do
      let(:item) do
        build(:item,
              barcode: '3610512345678',
              callnumber: 'ABC 123',
              permanent_location: build(:page_en_location),
              effective_location: build(:page_en_location))
      end

      it 'simplfies the display of the text of the destination library if there is only one possible' do
        visit new_request_path(item_id: '1234', origin: 'SAL3', origin_location: 'PAGE-EN')

        expect(page).not_to have_css('select')

        expect(page).to have_css('.form-group .control-label', text: 'Will be delivered to')
        expect(page).to have_css('.form-group .input-like-text', text: 'Engineering Library (Terman)')
      end
    end
  end

  describe 'libraries that should include themself in the pickup list' do
    context 'a standard library' do
      it 'does not include the configured library in the drop down' do
        visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')

        expect(page).to have_css('#request_destination option', count: standard_pickup_lib_total)
        expect(page).not_to have_css('option', text: media_label)
      end
    end

    context 'libraries that are configured' do
      let(:item) do
        build(:item,
              barcode: '3610512345678',
              callnumber: 'ABC 123',
              effective_location: build(:mmstacks_location),
              material_type: build(:multimedia_material_type))
      end

      it 'appear in the drop down' do
        visit new_request_path(item_id: '1234', origin: 'MEDIA-MTXT', origin_location: 'MM-STACKS')

        expect(page).to have_css('#request_destination option', count: standard_pickup_lib_total + 1)
        expect(page).to have_css('option', text: media_label)
      end
    end
  end
end
