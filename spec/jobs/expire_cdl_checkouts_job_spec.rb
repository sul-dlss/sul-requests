# frozen_string_literal: true

require 'rails_helper'

describe ExpireCdlCheckoutsJob, type: :job do
  before do
    expect(Patron).to receive(:find_by).and_return(patron)
  end

  let(:patron) { instance_double('Patron') }
  let(:checkouts) do
    [
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
                                 'comment' => 'CDL;;a:1;'
                               }
                             }
                           ] } } }
                         }
                       }
                     }),
      CircRecord.new({ 'key' => 'b', 'fields' => { 'overdue' => true } }),
      CircRecord.new({ 'key' => 'c', 'fields' => { 'overdue' => false } })
    ]
  end

  it 'checks in overdue items and calls the CdlWaitlistJob' do
    expect(patron).to receive(:checkouts).and_return checkouts
    expect(CircRecord).to receive(:find).and_return(checkouts[0], checkouts[1])
    expect(CdlWaitlistJob).to receive(:perform_now).with('a:1', checkout_date: Time.zone.parse('01-01-1970'))
    expect(CdlWaitlistJob).to receive(:perform_now).with('b', checkout_date: nil)
    subject.perform
  end
end
