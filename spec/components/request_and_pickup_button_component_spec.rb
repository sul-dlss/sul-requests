# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestAndPickupButtonComponent, type: :component do
  subject(:rendered) do
    with_controller_class RequestsController do
      render_inline(component)
    end
  end

  let(:component) { described_class.new(current_request: build(:request)) }

  before do
    stub_folio_holdings(:folio_single_holding)
  end

  it 'renders the component' do
    expect(rendered).to have_link 'Request & pickup', href: '/pages/new'
    expect(rendered).to have_selector 'dd[data-single-library-value="GREEN"]'
    expect(rendered).to have_selector 'dd span[data-scheduler-text="true"]'
  end
end
