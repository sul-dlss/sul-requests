# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestAndPickupButtonComponent, type: :component, unless: Settings.features.migration do
  subject(:rendered) do
    with_controller_class RequestsController do
      render_inline(component)
    end
  end

  let(:component) { described_class.new(current_request: build(:request)) }
  let(:destination) { Settings.ils.bib_model == 'Folio::Instance' ? 'GREEN-LOAN' : 'GREEN' }

  it 'renders the component' do
    expect(rendered).to have_link 'Request & pickup', href: '/pages/new'
    expect(rendered).to have_selector "dd[data-single-library-value='#{destination}']"
    expect(rendered).to have_selector 'dd span[data-scheduler-text="true"]'
  end
end
