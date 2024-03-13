# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'application/_item_selector.html.erb' do
  let(:user) { create(:sso_user) }

  before do
    view.bootstrap_form_for(request, url: '/', as: :request) do |f|
      @f = f
    end

    allow(view).to receive_messages(current_request: request, f: @f)
    render
  end

  context 'item with only one holding' do
    context 'from the holdings' do
      let(:request) { create(:request_with_holdings) }

      it 'displays the single call number' do
        expect(rendered).to have_css '.single-item-callnumber', text: 'ABC 123'
      end
    end

    context 'requested via barcode' do
      let(:request) { create(:request_with_multiple_holdings, barcode: '3610512345678') }

      it 'displays the single call number' do
        expect(rendered).to have_css '.single-item-callnumber', text: 'ABC 123'
      end
    end
  end

  context 'item with multiple holdings' do
    let(:request) { create(:mediated_page_with_holdings) }

    it 'shows an item selector' do
      expect(rendered).to have_css '[data-behavior="item-selector"]'

      expect(rendered).to have_field 'request[barcodes][45678901]'
      expect(rendered).to have_field 'request[barcodes][12345678]'
      expect(rendered).to have_field 'request[barcodes][89012345]'
    end
  end
end
