# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::AppointmentSelectionComponent, type: :component do
  let(:reading_rooms) { JSON.load_file('spec/fixtures/reading_rooms.json') }

  context 'with existing appointment and day only appointment reading room' do
    let(:appointment) { build(:aeon_appointment) }

    before do
      render_inline(described_class.new(appointment:))
    end

    it 'renders existing appointment time and date and placeholder for date to be selected' do
      within('.selected-appointment') do
        expect(page).to have_css('h4', text: 'Current')
        expect(page).to have_text('Mar 11, 2024')
        expect(page).to have_no_text('1:00 PM -  1:15 PM')
        expect(page).to have_css('h4', text: 'New')
        expect(page).to have_css('div[data-appointment-target="selection"]', text: 'Select date')
      end
    end
  end

  context 'with existing appointment and reading room with date and time' do
    let(:appointment) { build(:aeon_appointment) }

    before do
      appointment.reading_room = Aeon::ReadingRoom.from_dynamic(reading_rooms[2])
      render_inline(described_class.new(appointment:))
    end

    it 'renders existing appointment time and date and placeholder for date to be selected' do
      within('.selected-appointment') do
        expect(page).to have_css('h4', text: 'Current')
        expect(page).to have_text('Mar 11, 2024')
        expect(page).to have_text('1:00 PM -  1:15 PM')
        expect(page).to have_css('h4', text: 'New')
        expect(page).to have_css('div[data-appointment-target="selection"]', text: 'Select date and time')
      end
    end
  end

  context 'with new appointment' do
    before do
      render_inline(described_class.new(appointment: Aeon::Appointment.new))
    end

    it 'renders only the selection placeholder to be hidden' do
      expect(page).to have_no_text('Current')
      expect(page).to have_no_text('New')
      expect(page).to have_css('div[data-appointment-target="selection"].d-none')
    end
  end
end
