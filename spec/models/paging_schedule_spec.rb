# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagingSchedule do
  subject(:schedule) { described_class.new(from:, to:, time:, library_hours: stub_library_hours) }

  let(:time) { Time.zone.parse('2026-01-12 10:00 AM') }

  let(:stub_library_hours) { instance_double(LibraryHours) }
  let(:stub_business_days) { ((time.to_date)..(time.to_date + 10.days)).map(&:beginning_of_day).reject(&:on_weekend?) }
  let(:stub_schedule) do
    stub_business_days.map do |d|
      (d.change(hour: 9))..(d.change(hour: 20))
    end
  end

  before do
    allow(stub_library_hours).to receive_messages(next_schedule_for: stub_schedule,
                                                  business_days_for: stub_business_days)
  end

  describe '#schedule_for_request' do
    context 'paging from SAL3 to GREEN' do
      let(:from) { Folio::Types.locations.find_by(code: 'SAL3-STACKS') }
      let(:to) { 'GREEN' }

      it 'arrives in GREEN the next day' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-13 11:15 AM'))
      end
    end

    context 'paging from SAL3 to GREEN on Friday before the cut-off' do
      let(:from) { Folio::Types.locations.find_by(code: 'SAL3-STACKS') }
      let(:to) { 'GREEN' }
      let(:time) { Time.zone.parse('2026-01-16 10:00 AM') }

      it 'arrives in GREEN the next business day' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-19 11:15 AM'))
      end
    end

    context 'paging from SAL3 to GREEN on Friday after the cut-off' do
      let(:from) { Folio::Types.locations.find_by(code: 'SAL3-STACKS') }
      let(:to) { 'GREEN' }
      let(:time) { Time.zone.parse('2026-01-16 10:00 PM') }

      it 'arrives in GREEN a day later' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-20 11:15 AM'))
      end
    end

    context 'paging from GREEN TO GREEN' do
      let(:from) { Folio::Types.locations.find_by(code: 'GRE-STACKS') }
      let(:to) { 'GREEN' }

      it 'arrives in GREEN the same day' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-12 6:00 PM'))
      end
    end

    context 'paging from ART TO GREEN' do
      let(:from) { Folio::Types.locations.find_by(code: 'ART-STACKS') }
      let(:to) { 'GREEN' }

      it 'arrives in GREEN the next day' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-13 1:45 PM'))
      end
    end

    context 'paging from ART TO GREEN after the cut-off' do
      let(:from) { Folio::Types.locations.find_by(code: 'ART-STACKS') }
      let(:to) { 'GREEN' }
      let(:time) { Time.zone.parse('2026-01-12 1:00 PM') }

      it 'arrives in GREEN the following day' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-14 1:45 PM'))
      end
    end
  end

  # describe '#earliest_delivery_estimate' do
  # end

  # describe '#valid?' do
  # end
end
