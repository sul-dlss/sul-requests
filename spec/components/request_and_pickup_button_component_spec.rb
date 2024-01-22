# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestAndPickupButtonComponent, type: :component do
  subject(:rendered) do
    with_controller_class RequestsController do
      render_inline(component)
    end
  end

  let(:component) { described_class.new(current_request: build(:request)) }
  let(:destination) { 'GREEN-LOAN' }

  it 'renders the component' do
    expect(rendered).to have_link 'Request & pickup', href: '/pages/new'
    expect(rendered).to have_css "dd[data-single-library-value='#{destination}']"
    expect(rendered).to have_css 'dd span[data-scheduler-text="true"]'
  end
end
