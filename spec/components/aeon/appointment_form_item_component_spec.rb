# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::AppointmentFormItemComponent, type: :component do
  context 'with an existing request' do
    let(:request) do
      build(:aeon_request, :ead, call_number: 'M1234', item_volume: 'Box 1')
    end

    before do
      render_inline(described_class.for_request(dom_id: 'request-123', request:))
    end

    it 'renders the request item label with the selected item styling' do
      expect(page).to have_text 'Box 1'
    end

    it 'uses the rendered item label in the delete button accessible name' do
      expect(page).to have_css(
        'button[aria-labelledby="appointment-delete-label-request-123 appointment-item-label-request-123"]'
      )
      expect(page).to have_css('#appointment-delete-label-request-123', text: 'Delete')
      expect(page).to have_no_css('.selected-item-remove .visually-hidden')
    end

    it 'uses the Aeon request parameter scope' do
      expect(page).to have_field('aeon_request[appointment_id]')
    end
  end

  context 'without an existing request' do
    before do
      render_inline(described_class.template)
    end

    it 'renders a replaceable item label' do
      expect(page).to have_css('.selected-item-title', text: '__TITLE__')
    end

    it 'uses the patron request item parameter scope' do
      expect(page).to have_field('patron_request[aeon_item][__ID__][appointment_id]')
    end
  end
end
