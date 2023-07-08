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

  before do
    allow_any_instance_of(FolioClient).to receive(:resolve_to_instance_id).and_return('f1c52ab3-721e-5234-9a00-1023e034e2e8')
    stub_folio_holdings(:folio_single_holding)
  end

  it 'renders the component' do
    expect(rendered).to have_link 'Scan to PDF', href: '/scans/new'
    expect(rendered).to have_selector 'dd[data-single-library-value="SCAN"]'
    expect(rendered).to have_selector 'dd span[data-scheduler-text="true"]'
  end
end