# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'hold_recalls/_header.html.erb' do
  let(:origin) { 'GREEN' }
  let(:origin_location) { 'STACKS' }
  let(:current_request) do
    double('request', origin:, origin_location:, holdings:)
  end

  let(:holdings) do
    [instance_double(Searchworks::HoldingItem, current_location_code:)]
  end

  before do
    allow(view).to receive_messages(current_request:)
  end

  context 'with a blank current location' do
    let(:origin_location) { 'INPROCESS' }
    let(:current_location_code) { '' }

    it 'falls back to the home location' do
      render
      expect(rendered).to have_css('h1', text: 'Request in-process item')
      expect(rendered).not_to have_css('h1', text: 'checked-out')
    end
  end

  context 'when current location is ON-ORDER' do
    let(:current_location_code) { 'ON-ORDER' }

    it 'has the correct header' do
      render
      expect(rendered).to have_css('h1', text: 'Request on-order item')
    end
  end

  context 'when current location is INPROCESS' do
    let(:current_location_code) { 'INPROCESS' }

    it 'has the correct header' do
      render
      expect(rendered).to have_css('h1', text: 'Request in-process item')
    end
  end

  context 'when current location is checked out' do
    let(:current_location_code) { 'CHECKEDOUT' }

    it 'has the correct header' do
      render
      expect(rendered).to have_css('h1', text: 'Request checked-out item')
    end
  end

  context 'when there are no holdings' do
    let(:holdings) { [] }

    it 'falls back to the default title' do
      render
      expect(rendered).to have_css('h1', text: 'Request item')
    end
  end

  context 'when it is some other location' do
    let(:current_location_code) { 'SOMETHING-ELSE' }

    it 'falls back to the default title' do
      render
      expect(rendered).to have_css('h1', text: 'Request item')
    end
  end
end
