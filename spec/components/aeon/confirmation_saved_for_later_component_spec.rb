# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::ConfirmationSavedForLaterComponent, type: :component do
  let(:draft_request) { build(:aeon_request) }
  let(:submitted_request) { build(:aeon_request) }
  let(:request_group) { Aeon::RequestGrouping.new([draft_request, submitted_request]) }

  before do
    allow(draft_request).to receive_messages(draft?: true, submitted?: false, digital?: false)
    allow(submitted_request).to receive_messages(draft?: false, submitted?: true, digital?: false)
  end

  context 'with draft and submitted requests' do
    before { render_inline(described_class.new(request_group:)) }

    it 'renders the "also saved" message with count and schedule link' do
      expect(page).to have_text('You also saved 1 item for later.')
      expect(page).to have_text('Schedule them anytime')
      expect(page).to have_link('Saved for later', href: '/aeon_requests/drafts')
    end
  end

  context 'with only draft requests' do
    let(:request_group) { Aeon::RequestGrouping.new([draft_request]) }

    before { render_inline(described_class.new(request_group:)) }

    it 'renders the "saved" message' do
      expect(page).to have_text('You saved 1 item for later.')
    end
  end

  context 'with digitization draft requests' do
    before do
      allow(draft_request).to receive(:digital?).and_return(true)
      render_inline(described_class.new(request_group:))
    end

    it 'says "Complete" instead of "Schedule"' do
      expect(page).to have_text('Complete them anytime')
    end
  end

  context 'with no draft requests' do
    let(:request_group) { Aeon::RequestGrouping.new([submitted_request]) }

    before { render_inline(described_class.new(request_group:)) }

    it 'does not render' do
      expect(page).to have_no_text('saved')
    end
  end
end
