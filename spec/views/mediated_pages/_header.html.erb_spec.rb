require 'rails_helper'

describe 'mediated_pages/_header.html.erb' do
  let(:origin) { 'GREEN' }
  let(:origin_location) { 'STACKS' }
  let(:holdings) { [] }
  let(:current_request) do
    double('request', origin: origin, origin_location: origin_location, holdings: holdings)
  end
  before do
    allow(view).to receive_messages(current_request: current_request)
  end

  describe 'library level titles' do
    let(:origin) { 'HOPKINS' }
    it 'are returned when present' do
      render
      expect(rendered).to have_css('h1', text: 'Request delivery to campus library')
    end
  end

  describe 'location level titles' do
    let(:origin_location) { 'PAGE-MP' }
    it 'are returned when present' do
      render
      expect(rendered).to have_css('h1', text: 'Request delivery to campus library')
    end
  end

  describe 'default' do
    it 'falls back to the default title when there is no location' do
      render
      expect(rendered).to have_css('h1', text: 'Request on-site access')
    end
  end
end
