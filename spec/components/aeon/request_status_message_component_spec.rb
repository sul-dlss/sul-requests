# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::RequestStatusMessageComponent, type: :component do
  context 'with draft requests' do
    before do
      allow(request).to receive_messages(draft?: true)
      render_inline(described_class.new(request:))
    end

    context 'with digitization' do
      let(:request) { build(:aeon_request, :digitized) }

      it 'shows a warning that the request is missing pages/instructions' do
        expect(page).to have_text 'Pages/instructions not specified'
        expect(page).to have_css '.bi-exclamation-triangle-fill'
      end
    end

    context 'with reading room' do
      let(:request) { build(:aeon_request) }

      it 'shows a warning that the request is not scheduled' do
        expect(page).to have_text 'Not scheduled'
        expect(page).to have_css '.bi-exclamation-triangle-fill'
      end
    end
  end

  context 'with submitted requests' do
    let(:request) { build(:aeon_request) }

    before do
      allow(request).to receive_messages(draft?: false, cancelled?: false)
      render_inline(described_class.new(request:))
    end

    it 'does not render' do
      expect(page.text).to be_empty
    end
  end
end
