# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagingSchedule do
  subject(:schedule) { described_class.new(from: Folio::Types.locations.find_by(code: from), to:, time: request_time, library_hours: stub_library_hours) }

  let(:request_time) { Time.zone.parse('2026-01-12 10:00 AM') }

  let(:mar_schedule) do
    [
      (Time.zone.parse('2026-01-12 9:00 AM'))..(Time.zone.parse('2026-01-12 05:00 PM')),
      (Time.zone.parse('2026-01-13 9:00 AM'))..(Time.zone.parse('2026-01-13 05:00 PM')),
      (Time.zone.parse('2026-01-14 9:00 AM'))..(Time.zone.parse('2026-01-14 05:00 PM')),
      (Time.zone.parse('2026-01-15 9:00 AM'))..(Time.zone.parse('2026-01-15 05:00 PM')),
      (Time.zone.parse('2026-01-16 9:00 AM'))..(Time.zone.parse('2026-01-16 05:00 PM')),
      (Time.zone.parse('2026-01-20 9:00 AM'))..(Time.zone.parse('2026-01-20 05:00 PM'))
    ]
  end
  let(:art_schedule) do
    [
      (Time.zone.parse('2026-01-12 9:00 AM'))..(Time.zone.parse('2026-01-12 07:00 PM')),
      (Time.zone.parse('2026-01-13 9:00 AM'))..(Time.zone.parse('2026-01-13 07:00 PM')),
      (Time.zone.parse('2026-01-14 9:00 AM'))..(Time.zone.parse('2026-01-14 07:00 PM')),
      (Time.zone.parse('2026-01-15 9:00 AM'))..(Time.zone.parse('2026-01-15 07:00 PM')),
      (Time.zone.parse('2026-01-16 9:00 AM'))..(Time.zone.parse('2026-01-16 05:00 PM')),
      (Time.zone.parse('2026-01-20 9:00 AM'))..(Time.zone.parse('2026-01-20 07:00 PM'))
    ]
  end
  let(:sal3_schedule) do
    [
      (Time.zone.parse('2026-01-12 8:00 AM'))..(Time.zone.parse('2026-01-12 05:00 PM')),
      (Time.zone.parse('2026-01-13 8:00 AM'))..(Time.zone.parse('2026-01-13 05:00 PM')),
      (Time.zone.parse('2026-01-14 8:00 AM'))..(Time.zone.parse('2026-01-14 05:00 PM')),
      (Time.zone.parse('2026-01-15 8:00 AM'))..(Time.zone.parse('2026-01-15 05:00 PM')),
      (Time.zone.parse('2026-01-16 8:00 AM'))..(Time.zone.parse('2026-01-16 05:00 PM')),
      (Time.zone.parse('2026-01-20 8:00 AM'))..(Time.zone.parse('2026-01-20 05:00 PM'))
    ]
  end
  let(:green_schedule) do
    [
      (Time.zone.parse('2026-01-12 8:00 AM'))..(Time.zone.parse('2026-01-12 11:59 PM')),
      (Time.zone.parse('2026-01-13 8:00 AM'))..(Time.zone.parse('2026-01-13 11:59 PM')),
      (Time.zone.parse('2026-01-14 8:00 AM'))..(Time.zone.parse('2026-01-14 11:59 PM')),
      (Time.zone.parse('2026-01-15 8:00 AM'))..(Time.zone.parse('2026-01-15 11:59 PM')),
      (Time.zone.parse('2026-01-16 8:00 AM'))..(Time.zone.parse('2026-01-16 11:59 PM')),
      (Time.zone.parse('2026-01-17 8:00 AM'))..(Time.zone.parse('2026-01-17 07:00 PM')),
      (Time.zone.parse('2026-01-18 12:00 PM'))..(Time.zone.parse('2026-01-18 11:59 PM')),
      (Time.zone.parse('2026-01-20 8:00 AM'))..(Time.zone.parse('2026-01-20 11:59 PM')),
      (Time.zone.parse('2026-01-21 8:00 AM'))..(Time.zone.parse('2026-01-21 11:59 PM'))
    ]
  end

  let(:stub_library_hours) { instance_double(LibraryHours) }

  before do
    allow(stub_library_hours).to receive(:next_schedule_for) do |library_code|
      case library_code
      when 'GREEN'
        green_schedule
      when 'SAL3'
        sal3_schedule
      when 'ART'
        art_schedule
      when 'MARINE-BIO'
        mar_schedule
      end
    end

    allow(stub_library_hours).to receive(:business_days_for) do |library_code|
      stub_library_hours.next_schedule_for(library_code).map { |range| range.first.beginning_of_day }
    end
  end

  describe '#schedule_for_request' do
    context 'paging from SAL3 to GREEN' do
      let(:from) { 'SAL3-STACKS' }
      let(:to) { 'GREEN' }

      it 'arrives in GREEN the next day' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-13 11:15 AM'))
      end
    end

    context 'paging from SAL3 to GREEN on Friday before the cut-off' do
      let(:from) { 'SAL3-STACKS' }
      let(:to) { 'GREEN' }
      let(:request_time) { Time.zone.parse('2026-01-16 10:00 AM') }

      it 'arrives in GREEN the next business day' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-20 11:15 AM'))
      end
    end

    context 'paging from SAL3 to GREEN on Friday after the cut-off' do
      let(:from) { 'SAL3-STACKS' }
      let(:to) { 'GREEN' }
      let(:request_time) { Time.zone.parse('2026-01-16 10:00 PM') }

      it 'arrives in GREEN a day later' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-21 11:15 AM'))
      end
    end

    context 'paging from GREEN TO GREEN' do
      let(:from) { 'GRE-STACKS' }
      let(:to) { 'GREEN' }

      it 'arrives in GREEN the same day' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-12 6:00 PM'))
      end
    end

    context 'paging from ART TO GREEN' do
      let(:from) { 'ART-STACKS' }
      let(:to) { 'GREEN' }

      it 'arrives in GREEN the next day' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-13 1:45 PM'))
      end
    end

    context 'paging from ART TO GREEN after the cut-off' do
      let(:from) { 'ART-STACKS' }
      let(:to) { 'GREEN' }
      let(:request_time) { Time.zone.parse('2026-01-12 1:00 PM') }

      it 'arrives in GREEN the following day' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-14 1:45 PM'))
      end
    end

    context 'paging from GREEN to MARINE-BIO' do
      let(:from) { 'GRE-STACKS' }
      let(:to) { 'MARINE-BIO' }
      let(:request_time) { Time.zone.parse('2026-01-12 9:00 AM') }

      it 'arrives in MARINE-BIO at Wednesday EOD (available Thursday)' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-15 09:00 AM'))
      end
    end

    context 'paging from MARINE-BIO to GREEN' do
      let(:from) { 'MAR-STACKS' }
      let(:to) { 'GREEN' }
      let(:request_time) { Time.zone.parse('2026-01-12 9:00 AM') }

      it 'arrives in GREEN on Wednesday (having arrived in the mailroom on Tuesday)' do
        expect(schedule.schedule_for_request).to include(completed: Time.zone.parse('2026-01-14 10:30 AM'))
      end
    end
  end
end
