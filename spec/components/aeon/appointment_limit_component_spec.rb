# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::AppointmentLimitComponent, type: :component do
  before do
    render_inline(described_class.new(limit: 5, count: 3))
  end

  it 'renders the limit as text' do
    expect(page).to have_text('Item limit: 3/5')
  end

  it 'renders the limit visually' do
    expect(page).to have_css('[data-controller="progress-bar"][data-progress-bar-limit-value="5"][data-progress-bar-count-value="3"]')
  end

  context 'with no limit' do
    before do
      render_inline(described_class.new(limit: nil, count: 3))
    end

    it 'does not render' do
      expect(page).to have_no_text('Daily item limit')
    end
  end

  context 'with a limit greater than 10' do
    before do
      render_inline(described_class.new(limit: 10, count: 4))
    end

    it 'scales the filled dots appropriately' do
      expect(page).to have_css('[data-controller="progress-bar"][data-progress-bar-limit-value="10"][data-progress-bar-count-value="4"]')
    end
  end
end
