# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::RequestStatusPillComponent, type: :component do
  context 'with reading room requests' do
    let(:request) { build(:aeon_request) }

    context 'when saved for later' do
      before do
        allow(request).to receive_messages(status: :saved_for_later)
        render_inline(described_class.new(request:))
      end

      it 'shows the saved for later pill' do
        expect(page).to have_css '.saved-for-later', text: 'Reading room use'
      end
    end

    context 'when submitted with an appointment' do
      before do
        allow(request).to receive_messages(status: :submitted)
        render_inline(described_class.new(request:))
      end

      it 'shows the ready pill with check icon' do
        expect(page).to have_css '.ready', text: 'Reading room use'
      end
    end

    context 'when submitted without an appointment' do
      let(:request) { build(:aeon_request, :without_appointment) }

      before do
        allow(request).to receive_messages(status: :submitted)
        render_inline(described_class.new(request:))
      end

      it 'shows the pending pill with clock icon' do
        expect(page).to have_css '.pending', text: 'Reading room use'
      end
    end
  end

  context 'with digitization requests' do
    let(:request) { build(:aeon_request, :digitized) }

    context 'when saved for later' do
      before do
        allow(request).to receive_messages(status: :saved_for_later)
        render_inline(described_class.new(request:))
      end

      it 'shows the saved for later pill' do
        expect(page).to have_css '.saved-for-later', text: 'Digitization'
      end
    end

    context 'when submitted' do
      before do
        allow(request).to receive_messages(status: :submitted)
        render_inline(described_class.new(request:))
      end

      it 'shows the pending pill with clock icon' do
        expect(page).to have_css '.pending', text: 'Digitization'
      end
    end

    context 'when scan delivered' do
      before do
        allow(request).to receive_messages(status: :completed)
        render_inline(described_class.new(request:))
      end

      it 'shows the ready pill with check icon' do
        expect(page).to have_css '.ready', text: 'Digitization'
      end
    end
  end
end
