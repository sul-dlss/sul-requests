# frozen_string_literal: true

require 'rails_helper'

describe CdlWaitlistJob, type: :job do
  context 'when an item is not checkedout to pseudo patron' do
    let(:checkout) { instance_double(CircRecord, patron_barcode: 'abc123') }

    it 'returns early' do
      expect(CircRecord).to receive(:find).and_return(checkout)
      expect(subject.perform('abc', checkout_date: Time.zone.now)).to be_nil
    end
  end

  context 'when checkout dates do not match' do
    let(:checkout_time) { Time.zone.now }
    let(:checkout) { instance_double(CircRecord, patron_barcode: 'CDL-CHECKEDOUT', checkout_date: checkout_time) }

    it 'returns early' do
      expect(CircRecord).to receive(:find).and_return(checkout)
      expect(subject.perform('abc', checkout_date: checkout_time + 1.hour)).to be_nil
    end
  end

  context 'when there is an active hold record and its not next up' do
    let(:checkout) do
      instance_double(
        CircRecord,
        key: 'abc',
        patron_barcode: 'CDL-CHECKEDOUT',
        hold_records: [
          instance_double(HoldRecord, active?: true, cdl?: true, circ_record_key: 'abc', next_up_cdl?: false)
        ]
      )
    end

    it do
      expect(CircRecord).to receive(:find).and_return(checkout)
      expect do
        subject.perform('abc', checkout_date: nil)
      end.to raise_error Exceptions::CdlCheckinError, 'An active hold exists for abc'
    end
  end

  context 'when there is a next available hold' do
    let(:checkout) do
      instance_double(
        CircRecord,
        key: 'abc',
        checkout_date: Time.zone.now,
        item_barcode: '001234',
        patron_barcode: 'CDL-CHECKEDOUT',
        hold_records: [
          instance_double(
            HoldRecord, active?: true, cdl?: true, next_up_cdl?: false,
                        key: '1', circ_record_key: 'def', druid: 'druid'
          ),
          instance_double(HoldRecord, active?: true, cdl?: true, next_up_cdl?: true, key: '2', circ_record_key: 'abc')
        ]
      )
    end

    it 'cancels that next available hold if its next up and then proceed' do
      expect(CircRecord).to receive(:find).and_return(checkout)
      expect_any_instance_of(SymphonyClient).to receive(:cancel_hold).with('2')
      expect_any_instance_of(SymphonyClient).to receive(:check_in_item).with('001234')
      expect_any_instance_of(SymphonyClient).to receive(:update_hold).with('1', comment: 'CDL;druid;abc;1599865763;NEXT_UP')
      expect_any_instance_of(SymphonyClient).to receive(:check_out_item).and_return(
        {
          'circRecord' => {
            'fields' => {
              'checkOutDate' => 'Fri, 11 Sep 2020 16:09:23 PDT -07:00'
            }
          }
        }
      )
      expect(CdlWaitlistMailer).to receive(:youre_up).and_return(double(deliver_now: 'Delivered!'))
      expect(subject.perform('abc', checkout_date: nil)).to be 'Delivered!'
    end
  end
end
