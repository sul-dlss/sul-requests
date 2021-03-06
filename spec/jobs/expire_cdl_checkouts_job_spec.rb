# frozen_string_literal: true

require 'rails_helper'

describe ExpireCdlCheckoutsJob, type: :job do
  before do
    expect(Patron).to receive(:find_by).and_return(patron)
  end

  let(:patron) { instance_double('Patron') }
  let(:overdue_checkout) do
    CircRecord.new({
                     'key' => 'a:1',
                     'fields' => {
                       'checkOutDate' => '01-01-1970',
                       'overdue' => true,
                       'item' => {
                         'fields' => { 'bib' => { 'fields' => { 'holdRecordList' => [
                           {
                             'key' => 'a:1',
                             'fields' => {
                               'status' => 'PLACED',
                               'comment' => 'CDL;;a:1;' + Time.zone.parse('2017-07-06T16:03:00-07:00').to_i.to_s
                             }
                           }
                         ] } } }
                       }
                     }
                   })
  end

  let(:orphaned_checkout) do
    CircRecord.new({
                     'key' => 'b:1',
                     'fields' => {
                       'checkOutDate' => '01-01-1970',
                       'overdue' => false
                     }
                   })
  end

  let(:regular_checkout) do
    CircRecord.new({
                     'key' => 'c:1',
                     'fields' => {
                       'checkOutDate' => '2017-07-06T16:03:00-07:00',
                       'overdue' => false,
                       'item' => {
                         'fields' => { 'bib' => { 'fields' => { 'holdRecordList' => [
                           {
                             'key' => 'a:1',
                             'fields' => {
                               'status' => 'PLACED',
                               'comment' => 'CDL;;c:1;' + Time.zone.parse('2017-07-06T16:03:00-07:00').to_i.to_s
                             }
                           }
                         ] } } }
                       }
                     }
                   })
  end

  let(:checkouts) do
    [overdue_checkout, regular_checkout]
  end

  it 'checks in overdue items, cancels hold for active hold record, and calls the CdlWaitlistJob' do
    expect(patron).to receive(:checkouts).and_return checkouts
    expect(CircRecord).to receive(:find).and_return(*checkouts)
    expect(CdlWaitlistJob).to receive(:perform_now).with('a:1', checkout_date: anything)
    subject.perform
  end

  context 'with "orphaned" checkouts' do
    let(:checkouts) do
      [orphaned_checkout, regular_checkout]
    end

    it 'checks in orphaned items' do
      expect(patron).to receive(:checkouts).and_return checkouts
      expect(CircRecord).to receive(:find).and_return(*checkouts)
      expect(CdlWaitlistJob).to receive(:perform_now).with('b:1', checkout_date: anything)
      expect(CdlWaitlistJob).not_to receive(:perform_now).with('c:1', checkout_date: anything)
      subject.perform
    end
  end
end
