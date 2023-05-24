# frozen_string_literal: true

require 'rails_helper'

describe Scan do
  it 'has the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'Scan'
  end

  it 'validates based on if the item is scannable or not' do
    expect do
      described_class.create!(item_id: '1234',
                              origin: 'GREEN',
                              origin_location: 'STACKS',
                              section_title: 'Some chapter title')
    end.to raise_error(
      ActiveRecord::RecordInvalid, 'Validation failed: This item is not scannable'
    )
  end

  it 'allows scannabe only materials to be requested for scan' do
    stub_searchworks_api_json(build(:scannable_only_holdings))

    expect do
      described_class.create!(
        item_id: '123456',
        origin: 'SAL',
        origin_location: 'SAL-TEMP',
        section_title: 'Chapter 1'
      )
    end.not_to raise_error
  end

  describe 'requestable' do
    it { is_expected.not_to be_requestable_with_name_email }
    it { is_expected.not_to be_requestable_with_library_id }
  end

  describe '#item_limit' do
    it 'is 1' do
      expect(subject.item_limit).to eq 1
    end
  end

  describe '#submit!' do
    it 'submits the request to ILLIAD' do
      expect(SubmitScanRequestJob).to receive(:perform_later)
      subject.submit!
    end
  end

  describe 'send_approval_status!' do
    describe 'for library id users' do
      let(:subject) { create(:scan, user: create(:library_id_user)) }

      it 'does not send an approval status email' do
        expect do
          subject.send_approval_status!
        end.not_to change { RequestStatusMailer.deliveries.count }
      end
    end

    describe 'for everybody else' do
      let(:subject) { create(:scan, user: create(:sso_user)) }

      it 'sends an approval status email' do
        expect do
          subject.send_approval_status!
        end.to change { RequestStatusMailer.deliveries.count }.by(1)
      end
    end
  end
end
