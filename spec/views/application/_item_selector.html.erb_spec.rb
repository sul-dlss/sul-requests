# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'application/_item_selector.html.erb' do
  let(:user) { create(:sso_user) }

  before do
    view.bootstrap_form_for(request, url: '/') do |f|
      @f = f
    end

    allow(view).to receive_messages(current_request: request, f: @f)
    render
  end

  context 'item with only one holding' do
    context 'from the holdings' do
      let(:request) { create(:request_with_holdings) }

      it 'displays the single barcoded item' do
        expect(rendered).to have_selector '.form-control-static', text: 'ABC 123'
      end
    end

    context 'requested via barcode' do
      let(:request) { create(:request_with_multiple_holdings, barcode: '3610512345678') }

      it 'displays the single barcoded item' do
        expect(rendered).to have_selector '.form-control-static', text: 'ABC 123'
      end
    end
  end

  context 'item with multiple holdings' do
    let(:request) { create(:mediated_page_with_holdings) }

    it 'shows an item selector' do
      expect(rendered).to have_selector '[data-behavior="item-selector"]'

      expect(rendered).to have_selector 'input[name="mediated_page[barcodes][45678901]"]'
      expect(rendered).to have_selector 'input[name="mediated_page[barcodes][12345678]"]'
      expect(rendered).to have_selector 'input[name="mediated_page[barcodes][89012345]"]'
    end
  end
end
