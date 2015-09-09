require 'rails_helper'

describe ItemStatus do
  let(:request) { create(:request) }
  let(:barcode) { '3610512345' }

  subject { described_class.new(request, barcode) }

  describe '#status_object' do
    it 'fetches the status object from the request_status_data hash' do
      expect(subject.send(:status_object)).to eq(
        'approved' => false,
        'approver' => nil,
        'approval_time' => nil
      )
    end

    it 'is updated when the item is approved' do
      expect(request).to receive(:save!)
      subject.approve!('jstanford')
      expect(subject.send(:status_object)['approved']).to be true
      expect(subject.send(:status_object)['approver']).to eq 'jstanford'
      expect(subject.send(:status_object)['approval_time']).not_to be_nil
    end
  end

  describe '#approve!' do
    it 'persists the status to the request' do
      expect(request).to receive(:save!)
      subject.approve!('jstanford')

      status = request.request_status_data[barcode]

      expect(status['approved']).to be true
      expect(status['approver']).to eq 'jstanford'
      expect(status['approval_time']).not_to be_nil
    end

    it 'triggers a request to symphony when an item is approved' do
      expect(request).to receive(:save!)
      expect(SubmitSymphonyRequestJob).to receive(:perform_now).with(request, barcodes: [barcode])
      subject.approve!('jstanford')
    end
  end

  describe '#as_json' do
    let(:json) { subject.as_json }
    before { subject.approve!('jstanford') }
    it 'returns the identifier' do
      expect(json[:id]).to eq barcode
    end

    it 'returns the approved status' do
      expect(json[:approved]).to be true
    end

    it 'returns the approver' do
      expect(json[:approver]).to eq 'jstanford'
    end

    it 'returns the formatted approval time' do
      expect(json[:approval_time]).to eq(
        I18n.l(Time.zone.parse(subject.approval_time), format: :short)
      )
    end
  end

  describe 'accessors' do
    it 'aliases approved? to the status object' do
      expect(subject.approved?).to eq subject.send(:status_object)['approved']
    end

    it 'aliases approver to the status object' do
      expect(subject.approver).to eq subject.send(:status_object)['approver']
    end

    it 'aliases approval_time to the status object' do
      expect(subject.approval_time).to eq subject.send(:status_object)['approval_time']
    end
  end

  describe '#msgcode' do
    it 'returns the message code from the symphony request' do
      request.symphony_response_data = { requested_items: [{ barcode: '3610512345', msgcode: 'msgcode' }] }
      expect(subject.msgcode).to eq 'msgcode'
    end
  end
end
