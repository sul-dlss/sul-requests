# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'hold_recalls/_header.html.erb' do
  let(:origin) { 'GREEN' }
  let(:origin_location) { 'STACKS' }
  let(:current_request) do
    double('request', origin_library_code: origin, origin_location:, holdings:)
  end

  let(:holdings) { [holding] }
  let(:holding) do
    Folio::Item.new(
      barcode: '123',
      type: 'LC',
      callnumber: '456',
      material_type: 'book',
      permanent_location:,
      effective_location: effective_location || permanent_location,
      status:
    )
  end
  let(:permanent_location) { {} }
  let(:effective_location) { nil }
  let(:status) { 'Available' }

  before do
    allow(view).to receive_messages(current_request:)
  end

  context 'with an in-process item' do
    let(:status) { 'In process' }

    it 'shows the in-process header' do
      render
      expect(rendered).to have_css('h1', text: 'Request in-process item')
      expect(rendered).not_to have_css('h1', text: 'checked-out')
    end
  end

  context 'when the item is on-order' do
    let(:status) { 'On order' }

    it 'has the correct header' do
      render
      expect(rendered).to have_css('h1', text: 'Request on-order item')
    end
  end

  context 'when checked out' do
    let(:status) { 'Checked out' }

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
end
