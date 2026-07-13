# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatePickerComponent, type: :component do
  subject(:component) { described_class.new(:date, form:, data:, schedule:) }

  let(:data) { {} }
  let(:schedule) { DatePicker::Schedule.new }
  let(:form) do
    lookup_context = ActionView::LookupContext.new([])
    view = ActionView::Base.new(lookup_context, {}, nil)
    view.extend(Rails.application.routes.url_helpers)
    ActionView::Helpers::FormBuilder.new(:aeon_appointment, build(:aeon_appointment), view, {})
  end

  before { render_inline(component) }

  it 'sets data-date-picker-min-value to today by default' do
    expect(page).to have_css("[data-date-picker-min-value='#{Time.zone.today.iso8601}']")
  end

  it 'omits the disabled value attribute when the schedule has no closures' do
    expect(page).to have_no_css('[data-date-picker-disabled-value]')
  end

  it 'omits the availability url attribute when the schedule has none' do
    expect(page).to have_no_css('[data-date-picker-availability-url-value]')
  end

  context 'when the caller passes marked dates via data' do
    let(:data) { { 'date-picker-marked-value': %w[2026-06-10] } }

    it 'passes them through to the controller element' do
      expect(page).to have_css("[data-date-picker-marked-value='#{%w[2026-06-10].to_json}']")
    end
  end
end
