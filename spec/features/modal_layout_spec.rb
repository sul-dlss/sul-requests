# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Modal Layout' do
  let(:holdings_relationship) { double(:relationship, where: selected_items, all: [], single_checked_out_item?: false) }
  let(:selected_items) do
    [
      double(:item, barcode: '34567890', type: 'STKS', callnumber: 'ABC 123')
    ]
  end

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:new).and_return(double(:bib_data, title: 'Test title'))
    allow(HoldingsRelationshipBuilder).to receive(:build).and_return(holdings_relationship)
    stub_searchworks_api_json(build(:sal3_holdings))
  end

  it 'is not used when the modal param is not set' do
    visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

    expect(page).to have_css('#su-wrap')
  end

  it 'is used when the modal param is passed by the form and redirects' do
    stub_current_user(create(:sso_user))
    visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS', modal: true)

    expect(page).not_to have_css('#su-wrap')

    click_link 'Request & pickup'

    expect(page).not_to have_css('#su-wrap')
    expect(current_url).to match(/modal=true/)

    expect(page).to have_css('input[name="modal"]', visible: :hidden)

    first(:button, 'Send request').click

    expect(page).not_to have_css('#su-wrap')
    expect(current_url).to match(/modal=true/)
  end
end
