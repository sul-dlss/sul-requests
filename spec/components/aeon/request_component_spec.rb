# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::RequestComponent, type: :component do
  let(:request) { build(:aeon_request) }

  context 'digitization requests' do
    let(:request) { build(:aeon_request, :digitized) }

    context 'when in draft' do
      before do
        allow(request).to receive_messages(draft?: true)
        render_inline(described_class.new(request:))
      end

      it 'shows the draft status' do
        expect(page).to have_css '.draft'
        expect(page).to have_text 'Digitization'
        expect(page).to have_no_text 'Digitization ready'
        expect(page).to have_no_text 'Digitization pending'
      end
    end

    context 'when the digitization has been sent to the user' do
      before do
        allow(request).to receive_messages(completed?: true, scan_delivered?: true)
        render_inline(described_class.new(request:))
      end

      it 'shows that the scan has been delivered' do
        expect(page).to have_css '.ready'
        expect(page).to have_text 'Digitization ready'
        expect(page).to have_text 'Throwing a sinker ball at 94 mpg with wicked movement'
        expect(page).to have_link 'View in SearchWorks', href: 'https://searchworks.stanford.edu/view/12345678'
      end
    end

    context 'when the digitization request is in process' do
      before do
        allow(request).to receive_messages(completed?: false, scan_delivered?: false, submitted?: true)
        render_inline(described_class.new(request:))
      end

      it 'shows that digitization is pending' do
        expect(page).to have_css '.pending'
        expect(page).to have_text 'Digitization pending'
      end
    end
  end

  context 'reading room requests' do
    context 'when in draft' do
      before do
        allow(request).to receive_messages(draft?: true)
      end

      context 'with an appointment' do
        let(:request) { build(:aeon_request) }

        before do
          render_inline(described_class.new(request:))
        end

        it 'shows the draft status with no appointment details' do
          expect(page).to have_css '.draft'
          expect(page).to have_no_text 'Mar 11, 2024'
          expect(page).to have_no_text '1 pm - 1:15 pm (PDT)'
          expect(page).to have_no_text 'Field Reading Room'
        end
      end
    end

    context 'when submitted' do
      before do
        allow(request).to receive_messages(completed?: false, draft?: false, submitted?: true)
      end

      context 'with an appointment' do
        let(:request) { build(:aeon_request) }

        before do
          render_inline(described_class.new(request:))
        end

        it 'shows the appointment details' do
          expect(page).to have_css '.ready'
          expect(page).to have_text 'Reading room use'
          expect(page).to have_text 'Mar 11, 2024'
          expect(page).to have_text '1 pm - 1:15 pm (PDT)'
          expect(page).to have_text 'Field Reading Room'
          expect(page).to have_text 'Throwing a sinker ball at 94 mpg with wicked movement'
          expect(page).to have_link 'View in SearchWorks', href: 'https://searchworks.stanford.edu/view/12345678'
        end
      end

      context 'without an appointment' do
        let(:request) { build(:aeon_request, :without_appointment) }

        before do
          render_inline(described_class.new(request:))
        end

        it 'shows the pending reading room use status' do
          expect(page).to have_css '.pending'
          expect(page).to have_text 'Reading room use'
        end
      end
    end
  end
end
