# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::AppointmentDatePickerComponent, type: :component do
  subject(:component) do
    described_class.new(:date, form:,
                               data: { 'date-picker-disabled-value': disabled,
                                       'date-picker-marked-value': marked,
                                       'date-picker-open-days-value': open_days })
  end

  let(:aeon_client) { instance_double(AeonClient, available_appointments: [], closures: []) }
  let(:appointment) { build(:aeon_appointment, reading_room: nil) }
  let(:disabled) { nil }
  let(:open_days) { nil }
  let(:marked) { nil }
  let(:form) do
    lookup_context = ActionView::LookupContext.new([])
    view = ActionView::Base.new(lookup_context, {}, nil)
    view.extend(Rails.application.routes.url_helpers)
    ActionView::Helpers::FormBuilder.new(:aeon_appointment, appointment, view, {})
  end

  before do
    allow(Current).to receive(:aeon_client).and_return(aeon_client)
    render_inline(component)
  end

  it 'sets data-date-picker-min-value to today when no reading room is present' do
    expect(page).to have_css("[data-date-picker-min-value='#{Time.zone.today.iso8601}']")
  end

  context 'with disabled dates' do
    let(:disabled) { %w[2026-06-01 2026-06-15] }

    it 'encodes disabled dates as JSON on the controller element' do
      expect(page).to have_css("[data-date-picker-disabled-value='#{disabled.to_json}']")
    end
  end

  context 'with disabled daynames' do
    let(:open_days) { %w[Monday Tuesday Wednesday] }

    it 'encodes disabled dates as JSON on the controller element' do
      expect(page).to have_css("[data-date-picker-open-days-value='#{open_days.to_json}']")
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

  describe 'existing appointments' do
    subject(:component) { described_class.new(:date, form:, appointments:) }

    let(:sites) { ['SPECUA'] }
    let(:reading_room) { build(:aeon_reading_room, sites:) }
    let(:appointment) { build(:aeon_appointment, reading_room:) }
    let(:appointments) do
      [build(:aeon_appointment, reading_room:, start_time: Time.zone.parse('2026-06-10T09:00:00'),
                                stop_time: Time.zone.parse('2026-06-10T16:45:00'))]
    end

    context 'when the room books day-only appointments' do
      let(:sites) { ['SPECUA'] }

      it 'disables the dates the user already has an appointment on' do
        expect(page).to have_css("[data-date-picker-disabled-value='#{%w[2026-06-10].to_json}']")
      end

      it 'still marks those dates so the user sees their existing appointment' do
        expect(page).to have_css("[data-date-picker-marked-value='#{%w[2026-06-10].to_json}']")
      end
    end

    context 'when the room books slotted appointments' do
      let(:sites) { ['ARS'] }

      it 'marks the dates the user already has an appointment on' do
        expect(page).to have_css("[data-date-picker-marked-value='#{%w[2026-06-10].to_json}']")
      end

      it 'does not disable those dates' do
        expect(page).to have_no_css('[data-date-picker-disabled-value]')
      end
    end
  end
end
