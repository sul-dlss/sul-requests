# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Library Instructions' do
  let(:selected_items) do
    [double(:item, callnumber: 'ABC 123', barcode: '12345678', checked_out?: true, processing?: false, missing?: false, hold?: false,
                   on_order?: false, hold_recallable?: true)]
  end

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:new).and_return(double(:bib_data, title: 'Test title'))
    allow(HoldingsRelationshipBuilder).to receive(:build).and_return(selected_items)
    stub_searchworks_api_json(build(:library_instructions_holdings))
  end

  it 'returns the library instructions from the Settings' do
    visit new_request_path(item_id: '12345', origin: 'EDUCATION', origin_location: 'STACKS')
    within('p.needed-date-info-block') do
      expect(page).to have_content('The Education Library is closed for construction. Request items for pickup at another library.')
    end
  end
end
