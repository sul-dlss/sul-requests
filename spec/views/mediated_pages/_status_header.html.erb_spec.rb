require 'rails_helper'

describe 'mediated_pages/_status_header.html.erb' do
  let(:origin) { 'GREEN' }
  let(:origin_location) { 'STACKS' }
  let(:holdings) { [] }
  let(:ad_hoc_items) { [] }

  let(:current_request) do
    double('request', origin: origin, origin_location: origin_location, holdings: holdings, ad_hoc_items: ad_hoc_items)
  end

  before do
    allow(view).to receive_messages(current_request: current_request)
  end

  context 'with an empty request' do
    it 'should be blank' do
      render
      expect(rendered).to be_blank
    end
  end

  context 'with a request without approved holdings' do
    let(:holdings) { [double(request_status: double(approved?: false))] }

    it 'should be blank' do
      render
      expect(rendered).to be_blank
    end
  end

  context 'with approved holdings' do
    let(:holdings) do
      [
        double(request_status: double(approved?: true, msgcode: 'ok'), callnumber: 'XYZ'),
        double(request_status: double(approved?: false, msgcode: 'ok'), callnumber: 'ABC')
      ]
    end

    it 'should list the approve holdings' do
      render
      expect(rendered).to have_css(:dt, text: 'Approved')
      expect(rendered).to have_css(:dd, text: 'XYZ')
      expect(rendered).not_to have_css(:dd, text: 'ABC')
    end
  end

  context 'with approved ad-hoc holdings' do
    let(:ad_hoc_items) { %w(XYZ ABC) }

    it 'should list the approve holdings' do
      allow(current_request).to receive(:item_status).with('XYZ').and_return(double(approved?: true))
      allow(current_request).to receive(:item_status).with('ABC').and_return(double(approved?: false))

      render

      expect(rendered).to have_css(:dt, text: 'Approved')
      expect(rendered).to have_css(:dd, text: 'XYZ')
      expect(rendered).not_to have_css(:dd, text: 'ABC')
    end
  end
end
