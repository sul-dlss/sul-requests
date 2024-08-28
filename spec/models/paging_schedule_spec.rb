# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagingSchedule do
  describe '#schedule' do
    it 'returns an array of schedulers' do
      expect(described_class.schedule).to be_present
      expect(described_class.schedule).to be_a Array
      expect(
        described_class.schedule.all? do |schedule|
          schedule.is_a?(PagingSchedule::Scheduler)
        end
      ).to be true
    end
  end

  describe '#for' do
    it 'returns the schedule for the provided request' do
      schedule = described_class.for(build(:page, origin: 'SAL3', destination: 'GREEN'))
      expect(schedule).to be_a PagingSchedule::Scheduler
      expect(schedule.from).to eq 'SAL3'
      expect(schedule.to).to eq 'GREEN'
    end

    it 'returns the default/anywhere schedule if the destination is not configured' do
      schedule = described_class.for(build(:page, origin: 'SAL3', destination: 'SOMEWHERE-ELSE'))
      expect(schedule).to be_a PagingSchedule::Scheduler
      expect(schedule.from).to eq 'SAL3'
      expect(schedule.to).to eq 'SOMEWHERE-ELSE'
    end

    it 'raises an error when there is no schedule configured found' do
      expect do
        described_class.for(build(:page, origin: 'DOES-NOT-EXIST', destination: 'SOMEWHERE-ELSE'))
      end.to raise_error(PagingSchedule::ScheduleNotFound)
    end

    it 'raises an error if the location is probably sending via ILLiad' do
      page = build(:page, origin: 'SAL3', destination: 'GREEN')
      allow(page).to receive(:folio_location).and_return(double(pages_prefer_to_send_via_illiad?: true))
      expect do
        described_class.for(page)
      end.to raise_error(PagingSchedule::ScheduleNotFound)
    end
  end

  describe '.worst_case_delivery_day' do
    it 'is no more than 6 days away' do
      expect(described_class.worst_case_delivery_day).to eq Time.zone.today + 6.days
    end
  end

  describe PagingSchedule::Scheduler do
    describe 'will arrive text' do
      let(:scheduler) do
        described_class.new(to: 'SOMEWHERE', from: 'SOMEWHERE-ELSE', will_arrive_after: '12n')
      end

      it 'returns the after time with the appropriate prefix' do
        expect(scheduler.will_arrive_text).to eq '12n'
      end
    end

    describe '#by_time?' do
      let(:before_scheduler) do
        described_class.new(to: 'SOMEWHERE', from: 'SOMEWHERE-ELSE', before: '12:00pm') do
        end
      end
      let(:after_scheduler) do
        described_class.new(to: 'SOMEWHERE', from: 'SOMEWHERE-ELSE', after: '12:00pm') do
        end
      end

      it 'handles before attributes correctly' do
        expect(before_scheduler.by_time?(Time.zone.parse('11:00am'))).to be true
        expect(before_scheduler.by_time?(Time.zone.parse('1:00pm'))).to be false
      end

      it 'handles after attributes correctly' do
        expect(after_scheduler.by_time?(Time.zone.parse('11:00am'))).to be false
        expect(after_scheduler.by_time?(Time.zone.parse('1:00pm'))).to be true
      end
    end
  end

  describe 'estimate integration tests' do
    def earliest_delivery_estimate(from:, to:)
      request = double(origin_library_code: from, destination: to, destination_library_code: to, created_at: Time.zone.now)
      d = PagingSchedule.for(request).earliest_delivery_estimate
      d.estimated_delivery_day_to_destination
    end

    context 'shipping from SAL3 to GREEN' do
      context 'received before noon' do
        context 'when both the origin and destination are open' do
          before do
            data = {
              'data' => {
                'attributes' => {
                  'hours' => [
                    { 'open' => true, 'opens_at' => '2015-10-08' },
                    { 'open' => true, 'opens_at' => '2015-10-09' }
                  ]
                }
              }
            }

            response = LibraryHoursApi::Response.new(data)
            allow(LibraryHoursApi).to receive(:get).with('sal3', 'operations', anything).and_return(response)
            allow(LibraryHoursApi).to receive(:get).with('green', 'library-circulation', anything).and_return(response)
          end

          it 'takes a single day' do
            travel_to Time.zone.parse('2015-10-08T11:59:59') do
              expect(earliest_delivery_estimate(from: 'SAL3', to: 'GREEN')).to eq Date.parse('2015-10-09')
            end
          end
        end
      end

      context 'received after noon' do
        context 'when the origin and destination are closed for the weekend' do
          before do
            data = {
              'data' => {
                'attributes' => {
                  'hours' => [
                    { 'open' => true, 'opens_at' => '2015-10-08' },
                    { 'open' => true, 'opens_at' => '2015-10-09' },
                    { 'open' => false, 'opens_at' => '2015-10-10' },
                    { 'open' => false, 'opens_at' => '2015-10-11' },
                    { 'open' => true, 'opens_at' => '2015-10-12' }
                  ]
                }
              }
            }

            response = LibraryHoursApi::Response.new(data)
            allow(LibraryHoursApi).to receive(:get).with('sal3', 'operations', anything).and_return(response)
            allow(LibraryHoursApi).to receive(:get).with('green', 'library-circulation', anything).and_return(response)
          end

          it 'takes 2 business days' do
            travel_to Time.zone.parse('2015-10-08T12:00:01') do
              expect(earliest_delivery_estimate(from: 'SAL3', to: 'GREEN')).to eq Date.parse('2015-10-12')
            end
          end
        end
      end
    end

    context 'shipping from SAL to GREEN' do
      context 'received before 1pm' do
        context 'when both the origin and destination are open' do
          before do
            data = {
              'data' => {
                'attributes' => {
                  'hours' => [
                    { 'open' => true, 'opens_at' => '2015-10-08' }
                  ]
                }
              }
            }

            response = LibraryHoursApi::Response.new(data)
            allow(LibraryHoursApi).to receive(:get).with('sal12', 'operations', anything).and_return(response)
            allow(LibraryHoursApi).to receive(:get).with('green', 'library-circulation', anything).and_return(response)
          end

          it 'is same-day service' do
            travel_to Time.zone.parse('2015-10-08T11:59:59') do
              expect(earliest_delivery_estimate(from: 'SAL', to: 'GREEN')).to eq Date.parse('2015-10-08')
            end
          end
        end
      end

      context 'received after 1pm' do
        context 'when the origin and destination are both open' do
          before do
            data = {
              'data' => {
                'attributes' => {
                  'hours' => [
                    { 'open' => true, 'opens_at' => '2015-10-08' },
                    { 'open' => true, 'opens_at' => '2015-10-09' }
                  ]
                }
              }
            }

            response = LibraryHoursApi::Response.new(data)
            allow(LibraryHoursApi).to receive(:get).with('sal12', 'operations', anything).and_return(response)
            allow(LibraryHoursApi).to receive(:get).with('green', 'library-circulation', anything).and_return(response)
          end

          it 'arrives the next day' do
            travel_to Time.zone.parse('2015-10-08T12:00:01') do
              expect(earliest_delivery_estimate(from: 'SAL', to: 'GREEN')).to eq Date.parse('2015-10-09')
            end
          end
        end
      end
    end
  end
end
