# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::RequestMissingInformationComponent, type: :component do
  context 'draft digitization requests' do
    context 'with missing pages' do
      let(:request) { build(:aeon_request, :digitized, pages: nil) }

      before do
        allow(request).to receive_messages(draft?: true)
        render_inline(described_class.new(request:))
      end

      it 'shows the pages message' do
        expect(page).to have_text 'Pages/instructions not specified.'
      end
    end
  end

  context 'draft reading room requests' do
    context 'without an item selected' do
      let(:request) { build(:aeon_request, item_url: nil, call_number: nil) }

      before do
        allow(request).to receive_messages(draft?: true)
        render_inline(described_class.new(request:))
      end

      it 'shows the item message' do
        expect(page).to have_text 'Item not specified.'
      end
    end

    context 'without an item selected and without an appointment' do
      let(:request) { build(:aeon_request, :without_appointment, item_url: nil, call_number: nil) }

      before do
        allow(request).to receive_messages(draft?: true)
        render_inline(described_class.new(request:))
      end

      it 'shows the combined item & details message' do
        expect(page).to have_text 'Item and details not specified.'
      end
    end

    context 'missing an appointment only' do
      let(:request) { build(:aeon_request, :without_appointment, call_number: 'XYZ 123') }

      before do
        allow(request).to receive_messages(draft?: true)
        render_inline(described_class.new(request:))
      end

      it 'shows the appointment message' do
        expect(page).to have_text 'Appointment not scheduled.'
      end
    end
  end
end
