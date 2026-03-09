# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::RequestStatusPillComponent, type: :component do
  context 'with reading room requests' do
    let(:request) { build(:aeon_request) }

    context 'when draft' do
      before do
        allow(request).to receive_messages(draft?: true)
        render_inline(described_class.new(request:))
      end

      it 'shows the draft pill' do
        expect(page).to have_css '.draft', text: 'Reading room use'
        expect(page).to have_no_css '.bi-clock'
        expect(page).to have_no_css '.bi-check2-circle'
      end
    end

    context 'when submitted with an appointment' do
      before do
        allow(request).to receive_messages(completed?: false, draft?: false, submitted?: true)
        render_inline(described_class.new(request:))
      end

      it 'shows the ready pill with check icon' do
        expect(page).to have_css '.ready', text: 'Reading room use'
        expect(page).to have_css '.bi-check2-circle'
      end
    end

    context 'when submitted without an appointment' do
      let(:request) { build(:aeon_request, :without_appointment) }

      before do
        allow(request).to receive_messages(completed?: false, draft?: false, submitted?: true)
        render_inline(described_class.new(request:))
      end

      it 'shows the pending pill with clock icon' do
        expect(page).to have_css '.pending', text: 'Reading room use'
        expect(page).to have_css '.bi-clock'
      end
    end
  end

  context 'with digitization requests' do
    let(:request) { build(:aeon_request, :digitized) }

    context 'when draft' do
      before do
        allow(request).to receive_messages(draft?: true)
        render_inline(described_class.new(request:))
      end

      it 'shows the draft pill' do
        expect(page).to have_css '.draft', text: 'Digitization'
        expect(page).to have_no_text 'Digitization ready'
        expect(page).to have_no_text 'Digitization pending'
      end
    end

    context 'when submitted' do
      before do
        allow(request).to receive_messages(completed?: false, scan_delivered?: false, draft?: false, submitted?: true)
        render_inline(described_class.new(request:))
      end

      it 'shows the pending pill with clock icon' do
        expect(page).to have_css '.pending', text: 'Digitization pending'
        expect(page).to have_css '.bi-clock'
      end
    end

    context 'when scan delivered' do
      before do
        allow(request).to receive_messages(completed?: true, scan_delivered?: true)
        render_inline(described_class.new(request:))
      end

      it 'shows the ready pill with check icon' do
        expect(page).to have_css '.ready', text: 'Digitization ready'
        expect(page).to have_css '.bi-check2-circle'
      end
    end
  end
end
