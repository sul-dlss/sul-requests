require 'rails_helper'

describe PagingSchedule do
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

  describe '#configure' do
    it 'adds scheduler items to the schedule array' do
      expect(
        lambda do
          described_class.configure do
            when_paging from: 'SOMEWHERE', to: 'SOMEWHERE-ELSE', before: '10:00am' do
            end
          end
        end
      ).to change { described_class.schedule.count }.by(1)
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
      expect(schedule.to).to eq :anywhere
      expect(schedule.earliest_delivery_estimate.to).to eq 'SOMEWHERE-ELSE'
    end

    it 'raises an error when there is no schedule configured found' do
      expect(
        lambda do
          described_class.for(build(:page, origin: 'DOES-NOT-EXIST', destination: 'SOMEWHERE-ELSE'))
        end
      ).to raise_error(PagingSchedule::ScheduleNotFound)
    end
  end

  describe PagingSchedule::Scheduler do
    describe 'will arrive text' do
      let(:scheduler) do
        described_class.new(to: 'SOMEWHERE', from: 'SOMEWHERE-ELSE') do
        end
      end

      it 'returns the before time with the appropriate prefix' do
        scheduler.will_arrive(before: '10a')
        expect(scheduler.will_arrive_text).to eq 'before 10a'
      end

      it 'returns the after time with the appropriate prefix' do
        scheduler.will_arrive(after: '12n')
        expect(scheduler.will_arrive_text).to eq 'after 12n'
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

      it 'handles before attributes correctly ' do
        expect(before_scheduler.by_time?(Time.zone.parse('11:00am'))).to be true
        expect(before_scheduler.by_time?(Time.zone.parse('1:00pm'))).to be false
      end

      it 'handles after attributes correctly ' do
        expect(after_scheduler.by_time?(Time.zone.parse('11:00am'))).to be false
        expect(after_scheduler.by_time?(Time.zone.parse('1:00pm'))).to be true
      end
    end
  end

  describe PagingSchedule::Scheduler::Estimate do
    let(:scheduler) { double(to: 'GREEN', from: 'SAL3', days_later: 2, will_arrive_text: 'before 12n') }
    let(:business_day_double) { double('next_business_day') }
    before do
      expect(LibraryHours).to receive(:new).with('GREEN').at_least(:once).and_return(
        business_day_double
      )
    end

    describe 'estimating using buisness days' do
      before do
        expect(business_day_double).to receive(:next_business_day).with(
          Time.zone.today + 6.days
        ).at_least(:once).and_return(
          Time.zone.today + 6.days
        )
        expect(LibraryHours).to receive(:new).with('SAL3').at_least(:once).and_return(
          double(
            next_business_day: Time.zone.today + 2.days,
            business_days: [
              Time.zone.today + 2.days,
              Time.zone.today + 5.days,
              Time.zone.today + 6.days,
              Time.zone.today + 7.days
            ]
          )
        )
      end

      it 'does not count non-business days' do
        expect(described_class.new(scheduler).date).to eq Time.zone.today + 6.days
      end
    end

    describe 'attributes' do
      let(:business_days) { ((Time.zone.today + 2.days)...(Time.zone.today + 5.days)).to_a }
      before do
        expect(business_day_double).to receive(:next_business_day).with(
          Time.zone.today + 4.days
        ).at_least(:once).and_return(
          Time.zone.today + 5.days
        )
        allow(business_day_double).to receive(:business_days).and_return(business_days)
        expect(LibraryHours).to receive(:new).with('SAL3').at_least(:once).and_return(
          double(
            next_business_day: Time.zone.today + 2.days,
            business_days: business_days
          )
        )
      end
      describe '#date' do
        it 'returns the estimated date' do
          expect(described_class.new(scheduler).date).to eq Time.zone.today + 5.days
        end
      end

      describe '#as_json' do
        let(:json) { described_class.new(scheduler).as_json }
        it 'includes the date' do
          expect(json[:date]).to eq(Time.zone.today + 5.days)
        end

        it 'includes the time' do
          expect(json[:time]).to eq('before 12n')
        end

        it 'includes the text representation' do
          expect(json[:text]).to eq("#{I18n.l(Time.zone.today + 5.days, format: :long)}, before 12n")
        end

        it 'includes the destination\'s business days' do
          expect(json[:destination_business_days]).to eq business_days
        end
      end

      describe '#to_s' do
        it 'returns the text representation' do
          expect(
            described_class.new(scheduler).to_s
          ).to eq "#{I18n.l(Time.zone.today + 5.days, format: :long)}, before 12n"
        end
      end
    end
  end
end
