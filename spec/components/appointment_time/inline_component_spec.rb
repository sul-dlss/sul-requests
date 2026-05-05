# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppointmentTime::InlineComponent, type: :component do
  let(:start_time) { Time.zone.parse('2026-05-12T14:00:00Z') }
  let(:stop_time) { Time.zone.parse('2026-05-12T16:00:00Z') }
  let(:time_block) { ScheduledTimeBlock.new(start_time:, stop_time:, location: 'Special Collections', day_only: false) }

  it 'renders the date' do
    render_inline(described_class.new(time_block:))
    expect(page).to have_text(I18n.l(start_time, format: :date_only))
  end

  it 'renders the time range' do
    render_inline(described_class.new(time_block:))
    expect(page).to have_text("#{I18n.l(start_time, format: :time_only)} - #{I18n.l(stop_time, format: :time_only)}")
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

  context 'when the block is date-only' do
    let(:time_block) { ScheduledTimeBlock.new(start_time:, stop_time:, location: 'Special Collections', day_only: true) }

    it 'omits the time range' do
      render_inline(described_class.new(time_block:))
      expect(page).to have_no_text(I18n.l(start_time, format: :time_only))
    end
  end

  context 'when the block has no start_time' do
    let(:time_block) { ScheduledTimeBlock.new(start_time: nil, stop_time:, location: 'Special Collections', day_only: false) }

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
