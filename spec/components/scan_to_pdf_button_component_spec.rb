# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScanToPdfButtonComponent, type: :component do
  subject(:rendered) do
    with_controller_class RequestsController do
      render_inline(component)
    end
  end

  let(:current_request) { build(:request, item_title: 'foo') }
  let(:component) { described_class.new(current_request:) }

  it 'renders the component' do
    expect(rendered).to have_link 'Scan to PDF', href: '/scans/new'
    expect(rendered).to have_selector 'dd[data-single-library-value="SCAN"]'
    expect(rendered).to have_selector 'dd span[data-scheduler-text="true"]'
  end
end
