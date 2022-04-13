# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CdlAvailability do
  describe '#available' do
    let(:subject) { described_class.new('123456') }

    context 'when no items exist and cannot be found' do
      it do
        expect(subject.available).to include(
          available: false,
          dueDate: nil,
          items: 0,
          loanPeriod: 2.hours,
          waitlist: 0
        )
      end
    end

    context 'when items exist and one is available' do
      before do
        allow(CatalogInfo).to receive(:find).with('123456', return_holds: true).and_return(catalog_info)
      end

      let(:catalog_info) do
        instance_double(CatalogInfo,
                        callkey: 'xyz',
                        loan_period: 2.hours,
                        hold_records: Array.new(3) do |x|
                          instance_double(HoldRecord, circ_record_key: x, key: x, next_up_cdl?: false)
                        end,
                        items: items)
      end
      let(:items) do
        [
          instance_double(CatalogInfo, barcode: '12345', cdlable?: true, current_location: 'CDL-RESERVE')
        ]
      end

      it do
        stub_symphony(
          :circ_information,
          {
            'currentStatus' => 'ON_SHELF'
          }
        )
        expect(subject.available).to include(
          available: true
        )
      end
    end

    context 'when items exist and none are available' do
      before do
        allow(CatalogInfo).to receive(:find).with('123456', return_holds: true).and_return(catalog_info)
      end

      let(:catalog_info) do
        instance_double(CatalogInfo,
                        callkey: 'xyz',
                        loan_period: 2.hours,
                        hold_records: [
                          instance_double(HoldRecord, circ_record_key: 0, key: 0, next_up_cdl?: true),
                          instance_double(HoldRecord, circ_record_key: nil, key: 1, next_up_cdl?: false),
                          instance_double(HoldRecord, circ_record_key: nil, key: 2, next_up_cdl?: false)
                        ],
                        items: items)
      end
      let(:items) do
        [
          instance_double(CatalogInfo, barcode: '12345', cdlable?: true, current_location: 'CDL-RESERVE')
        ]
      end

      it do
        stub_symphony(
          :circ_information,
          {
            'dueDate' => '2020-09-09T15:16:50-06:00'
          }
        )
        expect(subject.available).to include(
          available: false,
          dueDate: DateTime.parse('2020-09-09T15:16:50-06:00'),
          items: 1,
          nextUps: [0]
        )
      end
    end
  end
end
