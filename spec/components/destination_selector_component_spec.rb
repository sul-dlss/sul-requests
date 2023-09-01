# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DestinationSelectorComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:rendered) { render_inline(component) }
  let(:form) { ActionView::Helpers::FormBuilder.new(nil, request, vc_test_controller.view_context, {}) }

  describe 'single library' do
    let(:request) { build(:request, origin: 'SAL3', origin_location: 'PAGE-EN', bib_data:) }
    let(:item) do
      build(:item,
            barcode: '3610512345678',
            callnumber: 'ABC 123',
            effective_location: build(:page_en_location))
    end

    let(:bib_data) { double(:bib_data, title: 'Test title', request_holdings: [item]) }

    it 'returns library text and a hidden input w/ the destination library' do
      expect(rendered).to have_css('.form-group .control-label', text: 'Will be delivered to')
      expect(rendered).to have_css('.form-group .input-like-text', text: 'Engineering Library (Terman)')
      expect(rendered).to have_css('input[type="hidden"][value="ENG"]', visible: :hidden)
    end
  end

  describe 'multiple libraries' do
    let(:request) { create(:request, origin: 'SAL3', origin_location: 'PAGE-HP') }

    it 'creates a select list' do
      expect(rendered).to have_select 'Deliver to'
    end

    context 'with a destination' do
      let(:request) { create(:request, origin: 'SAL3', destination: 'ART', origin_location: 'PAGE-HP') }

      before do
        allow(request).to receive(:pickup_destinations).and_return(['GREEN', 'HOPKINS', 'ART'])
      end

      it 'defaults to the destination library' do
        expect(rendered).to have_select 'Deliver to', selected: 'Art & Architecture Library (Bowes)'
      end
    end
  end
end
