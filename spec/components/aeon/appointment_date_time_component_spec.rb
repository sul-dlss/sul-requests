# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::AppointmentDateTimeComponent, type: :component do
  before { render_inline(described_class.new(appointment:, location: location)) }

  let(:location) { nil }

  context 'with an Aeon::Appointment (full date/time, with reading room)' do
    let(:appointment) { build(:aeon_appointment) }

    it 'renders the date and time range' do
      expect(page).to have_text('Mar 11, 2024')
      expect(page).to have_text('1:00 pm - 1:15 pm')
    end
  end

  context 'with an Aeon::Activity that has both dates' do
    let(:appointment) { build(:aeon_activity) }

    it 'renders both the date and the time range' do
      expect(page).to have_text('Feb 19, 2026')
      expect(page).to have_text('12:00 pm - 1:00 pm')
    end
  end

  context 'with an Aeon::Activity missing stop_time' do
    let(:appointment) { build(:aeon_activity, stop_time: nil) }

    it 'renders the date and the start time alone' do
      expect(page).to have_text('Feb 19, 2026')
      expect(page).to have_text('12:00 pm')
      expect(page).to have_no_text('-')
    end
  end

  context 'with an Aeon::Activity missing both dates' do
    let(:appointment) { build(:aeon_activity, start_time: nil, stop_time: nil) }

    it 'omits the date and time range entirely' do
      expect(page).to have_no_css('i.bi-calendar')
      expect(page).to have_no_css('i.bi-clock')
    end

    context 'when a location is provided' do
      let(:location) { 'Field Reading Room' }

      it 'still renders the location' do
        expect(page).to have_text('Field Reading Room')
      end
    end
  end
end
