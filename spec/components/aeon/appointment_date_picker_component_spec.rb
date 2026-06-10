# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::AppointmentDatePickerComponent, type: :component do
  subject(:component) do
    described_class.new(:date, form:,
                               data: { 'date-picker-disabled-value': disabled,
                                       'date-picker-marked-value': marked,
                                       'date-picker-open-days-value': open_days })
  end

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

  before { render_inline(component) }

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

  context 'with a reading room that has a full-day closure' do
    subject(:component) { described_class.new(:date, form:, reading_room:) }

    # Pick a Monday safely inside the picker's [min, max] window.
    let(:closure_date) { Date.current.next_occurring(:monday) + 2.weeks }
    let(:reading_room) do
      rr = build(:aeon_reading_room,
                 closures: [Aeon::ReadingRoomClosures.new(
                   start_date: closure_date.in_time_zone.beginning_of_day,
                   end_date: closure_date.in_time_zone.end_of_day
                 )])
      allow(rr).to receive(:next_appointment).and_return(nil)
      rr
    end

    it 'includes the closure date in the disabled-value' do
      expect(page).to have_css("[data-date-picker-disabled-value*='#{closure_date.iso8601}']")
    end
  end
end
