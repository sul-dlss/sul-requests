# frozen_string_literal: true

require 'rails_helper'

describe CdlWaitlistJob, type: :job do
  context 'when an item is not checkedout to pseudo patron' do
    let(:checkout) { instance_double(Symphony::CircRecord, patron_barcode: 'abc123') }

    it 'returns early' do
      expect(Symphony::CircRecord).to receive(:find).and_return(checkout)
      expect(subject.perform('abc', checkout_date: Time.zone.now)).to be_nil
    end
  end

  context 'when checkout dates do not match' do
    let(:checkout_time) { Time.zone.now }
    let(:checkout) { instance_double(Symphony::CircRecord, patron_barcode: 'CDL-CHECKEDOUT', checkout_date: checkout_time) }

    it 'returns early' do
      expect(Symphony::CircRecord).to receive(:find).and_return(checkout)
      expect(subject.perform('abc', checkout_date: checkout_time + 1.hour)).to be_nil
    end
  end

  context 'when there is an active hold record' do
    let(:checkout) do
      instance_double(
        Symphony::CircRecord,
        key: 'abc',
        checkout_date: Time.zone.now,
        item_barcode: '001234',
        patron_barcode: 'CDL-CHECKEDOUT',
        hold_records: [
          instance_double(
            Symphony::HoldRecord, key: '1', druid: 'druid', active?: true, cdl?: true, circ_record_key: 'abc', next_up_cdl?: false,
                                  comment: 'CDL;druid;abc;1599;ACTIVE', cdl_waitlisted?: false
          )
        ]
      )
    end

    it 'cancels it' do
      expect(Symphony::CircRecord).to receive(:find).and_return(checkout)
      expect_any_instance_of(SymphonyClient).to receive(:check_in_item).with('001234').and_return({})
      expect_any_instance_of(SymphonyClient).to receive(:cancel_hold).with('1').and_return({})
      expect_any_instance_of(SymphonyClient).to receive(:update_hold).with('1', comment: 'CDL;druid;abc;1599;EXPIRED').and_return({})
      expect(CdlWaitlistMailer).not_to receive(:hold_expired)
      subject.perform('abc', checkout_date: nil)
    end
  end

  context 'when there is a next available hold' do
    let(:expiring_hold) do
      instance_double(Symphony::HoldRecord, active?: true, cdl?: true, next_up_cdl?: true, cdl_waitlisted?: false,
                                            key: '2', circ_record_key: 'abc', comment: 'CDL;druid;abc;1599865763;NEXT_UP')
    end

    let(:checkout) do
      instance_double(
        Symphony::CircRecord,
        key: 'abc',
        checkout_date: Time.zone.now,
        item_barcode: '001234',
        patron_barcode: 'CDL-CHECKEDOUT',
        hold_records: [
          instance_double(
            Symphony::HoldRecord, active?: true, cdl?: true, next_up_cdl?: false, cdl_waitlisted?: true,
                                  key: '1', circ_record_key: 'def', druid: 'druid'
          ),
          expiring_hold
        ]
      )
    end

    it 'cancels that next available hold if its next up and then proceed' do
      expect(Symphony::CircRecord).to receive(:find).and_return(checkout)
      expect(CdlWaitlistMailer).to receive(:hold_expired).with('2').and_return(double(deliver_later: 'Delivered!'))
      expect_any_instance_of(SymphonyClient).to receive(:cancel_hold).with('2').and_return({})
      expect_any_instance_of(SymphonyClient).to receive(:check_in_item).with('001234').and_return({})
      expect_any_instance_of(SymphonyClient).to receive(:update_hold).with('1', comment: 'CDL;druid;abc;1599865763;NEXT_UP').and_return({})
      expect_any_instance_of(SymphonyClient).to receive(:update_hold).with('2', comment: 'CDL;druid;abc;1599865763;MISSED').and_return({})
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
