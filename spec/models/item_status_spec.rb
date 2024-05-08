# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemStatus do
  subject { described_class.new(request, barcode) }

  let(:request) { create(:mediated_page_with_single_holding) }
  let(:barcode) { '3610512345' }

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

    describe 'request approval status' do
      context 'when all items are not approved' do
        before { expect(request).to receive(:all_approved?).and_return(false) }

        it 'is not updated' do
          expect(request).not_to be_approved
          subject.approve!('jstanford')
          expect(request).not_to be_approved
        end
      end

      context 'when all items are approved' do
        before { expect(request).to receive(:all_approved?).and_return(true) }

        it 'is set to approved' do
          expect(request).not_to be_approved
          subject.approve!('jstanford')
          expect(request).to be_approved
        end
      end
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

    it 'returns the symphony msgcode for the item' do
      expect(json[:msgcode]).to eq '209'
    end

    it 'returns the symphony status text for the item' do
      expect(json[:text]).to eq 'Hold placed'
    end

    it 'returns the formatted approval time' do
      expect(json[:approval_time]).to eq(
        I18n.l(Time.zone.parse(subject.approval_time), format: :short)
      )
    end

    it 'returns the errored boolean' do
      expect(json[:errored]).to be false
    end

    context 'symphony errors' do
      let(:request) { create(:mediated_page_with_symphony_errors) }
      let(:barcode) { '12345678901234' }

      it 'returns user level error codes' do
        expect(json[:usererr_code]).to eq 'U003'
      end

      it 'returns item level error codes' do
        expect(json[:msgcode]).to eq '209'
      end

      it 'returns the usererr_text when present' do
        expect(json[:text]).to eq 'Blocked user'
      end

      it 'returns the errored boolean' do
        expect(json[:errored]).to be true
      end
    end
  end

  describe '#errored?' do
    let(:request) { build(:mediated_page) }

    before do
      request.symphony_response_data = build(:symphony_page_with_expired_user)
    end

    it 'is marked as errored' do
      expect(subject).to be_errored
    end

    context 'for an approved request' do
      before do
        request.approved!
      end

      it 'is still marked as errored' do
        expect(subject).to be_errored
      end
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

    it 'aliases msgcode to the symphony response object' do
      expect(subject.msgcode).to eq '209'
    end

    it 'aliases text to the symphony response object' do
      expect(subject.text).to eq 'Hold placed'
    end
  end
end
