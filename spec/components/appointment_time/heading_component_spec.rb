# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppointmentTime::HeadingComponent, type: :component do
  let(:start_time) { Time.zone.parse('2026-05-12T14:00:00Z') }
  let(:stop_time) { Time.zone.parse('2026-05-12T16:00:00Z') }
  let(:time_block) { ScheduledTimeBlock.new(start_time:, stop_time:, location: 'Special Collections', day_only: false) }

  it 'renders the date' do
    render_inline(described_class.new(time_block:))
    expect(page).to have_text(I18n.l(start_time, format: :date_only))
  end

  it 'renders the time range without an "Open hours:" prefix' do
    render_inline(described_class.new(time_block:))
    expect(page).to have_text("#{I18n.l(start_time, format: :time_only)} - #{I18n.l(stop_time, format: :time_only)}")
    expect(page).to have_no_text('Open hours:')
  end

  it 'applies the icon_class to the icons' do
    render_inline(described_class.new(time_block:, icon_class: 'me-1 text-green'))
    expect(page).to have_css('i.me-1.text-green', count: 2)
  end

  it 'omits the location by default' do
    render_inline(described_class.new(time_block:))
    expect(page).to have_no_text('Special Collections')
  end

  context 'with with_location: true' do
    it 'renders the location' do
      render_inline(described_class.new(time_block:, with_location: true))
      expect(page).to have_text('Special Collections')
    end
  end

  context 'when the block is date-only and show_open_hours is true' do
    let(:time_block) { ScheduledTimeBlock.new(start_time:, stop_time:, location: nil, day_only: true) }

    it 'renders the time range with an "Open hours:" prefix' do
      render_inline(described_class.new(time_block:, show_open_hours: true))
      expect(page).to have_text("Open hours: #{I18n.l(start_time, format: :time_only)} - #{I18n.l(stop_time, format: :time_only)}")
    end
  end

  context 'when the block is date-only and show_open_hours is false' do
    let(:time_block) { ScheduledTimeBlock.new(start_time:, stop_time:, location: nil, day_only: true) }

    it 'omits the time range entirely' do
      render_inline(described_class.new(time_block:, show_open_hours: false))
      expect(page).to have_no_text('Open hours')
      expect(page).to have_no_text("#{I18n.l(start_time, format: :time_only)} - #{I18n.l(stop_time, format: :time_only)}")
    end
  end

  context 'when the block has no start_time' do
    let(:time_block) { ScheduledTimeBlock.new(start_time: nil, stop_time:, location: nil, day_only: false) }

    it 'does not render' do
      render_inline(described_class.new(time_block:))
      expect(page.text).to be_empty
    end
  end

  context 'when the block is nil' do
    it 'does not render' do
      render_inline(described_class.new(time_block: nil))
      expect(page.text).to be_empty
    end
  end
end
