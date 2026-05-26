# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::AppointmentDatePickerComponent, type: :component do
  subject(:component) { described_class.new(appointment:, disabled:, marked:) }

  let(:aeon_client) { instance_double(AeonClient, available_appointments: []) }
  let(:appointment) { build(:aeon_appointment) }
  let(:disabled) { [] }
  let(:marked) { [] }

  before do
    allow(AeonClient).to receive(:new).and_return(aeon_client)
    allow(appointment.reading_room).to receive(:available_appointments).and_return([])
    render_inline(component)
  end

  it 'sets data-date-picker-min-value to today when no next appointment is present' do
    expect(page).to have_css("[data-date-picker-min-value='#{5.days.from_now.to_date.iso8601}']")
  end

  context 'with disabled dates' do
    let(:disabled) { %w[2026-06-01 2026-06-15] }

    it 'encodes disabled dates as JSON on the controller element' do
      expect(page).to have_css("[data-date-picker-disabled-value='#{disabled.to_json}']")
    end
  end

  context 'without disabled dates' do
    it 'omits the disabled value attribute' do
      expect(page).to have_no_css('[data-date-picker-disabled-value]')
    end
  end

  context 'with marked dates' do
    let(:marked) { %w[2026-06-10] }

    it 'encodes marked dates as JSON on the controller element' do
      expect(page).to have_css("[data-date-picker-marked-value='#{marked.to_json}']")
    end
  end

  context 'without marked dates' do
    it 'omits the marked value attribute' do
      expect(page).to have_no_css('[data-date-picker-marked-value]')
    end
  end
end
