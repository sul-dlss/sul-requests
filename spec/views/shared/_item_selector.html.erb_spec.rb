# frozen_string_literal: true

require 'rails_helper'

describe 'shared/_item_selector.html.erb' do
  let(:user) { create(:webauth_user) }

  before do
    allow(SULRequests::Application.config).to receive(:ad_hoc_item_commentable_libraries).and_return(['SPEC-COLL'])
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

  context 'item that accepts ad-hoc holdings' do
    let(:request) { create(:mediated_page_with_holdings, user: user, ad_hoc_items: ['ZZZ 123', 'ZZZ 321']) }

    it 'shows the ad-hoc item field' do
      expect(rendered).to have_selector '[data-behavior="ad-hoc-items"]'
    end
  end

  context 'with an existing request' do
    let(:request) do
      create(:mediated_page_with_holdings, user: user,
                                           barcodes: %w(12345678),
                                           ad_hoc_items: ['ZZZ 123', 'ZZZ 321'])
    end

    it 'pre-selects any selected items' do
      expect(rendered).to have_selector 'input[name="mediated_page[barcodes][12345678]"][checked="checked"]'
    end

    it 'populates the ad-hoc items' do
      expect(rendered).to have_selector '[data-behavior="ad-hoc-items"]'
      expect(rendered).to have_selector '[name="mediated_page[ad_hoc_items][]"][value="ZZZ 123"]', hidden: true
      expect(rendered).to have_selector '[name="mediated_page[ad_hoc_items][]"][value="ZZZ 321"]', hidden: true
    end
  end
end
