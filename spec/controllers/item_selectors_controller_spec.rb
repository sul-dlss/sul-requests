# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemSelectorsController do
  render_views

  let(:folio_instance) { build(:checkedout_holdings) }
  let(:checked_out_item) { folio_instance.items.second }
  let(:circulation_status) do
    [
      {
        'id' => checked_out_item.id,
        'queueTotalLength' => 2,
        'dueDate' => '2026-08-12T12:00:00.000+00:00'
      }
    ]
  end

  before do
    stub_folio_instance_json(folio_instance)
    allow_any_instance_of(FolioGraphqlClient).to receive(:item_circulation_status).and_return(circulation_status) # rubocop:disable RSpec/AnyInstance
    allow(controller).to receive(:current_ability).and_return(double(can?: false, cannot?: false))
    request.headers['Turbo-Frame'] = 'item_selector_circulation'
  end

  it 'renders the hydrated item selector in a turbo frame' do
    get :show, params: { instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS' }

    document = response.parsed_body
    checkbox = document.at_css("[data-item-selector-id-param='#{checked_out_item.id}']")

    expect(response).to be_successful
    expect(response.body).to include('<turbo-frame id="item_selector_circulation">')
    expect(document.text).to include('Due Aug 12, 2026')
    expect(checkbox['data-item-selector-duequeueinfo-param']).to include('There is a waitlist')
  end
end
