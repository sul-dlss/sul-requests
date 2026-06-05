# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::RequestFulfillmentComponent, type: :component do
  context 'when the request was cancelled by staff' do
    let(:request) { build(:aeon_request, :cancelled_by_staff) }

    before { render_inline(described_class.new(request:)) }

    it 'shows the cancelled-by-staff message' do
      expect(page).to have_css '.request-fulfillment .text-digital-red', text: 'Cancelled by staff'
    end
  end
end
