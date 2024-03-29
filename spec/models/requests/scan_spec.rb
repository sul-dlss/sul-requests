# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scan do
  before do
    allow(Folio::Instance).to receive(:fetch)
  end

  it 'has the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'Scan'
  end

  it 'validates based on if the item is scannable or not' do
    expect do
      described_class.create!(item_id: '1234',
                              origin: 'GREEN',
                              origin_location: 'GRE-STACKS',
                              section_title: 'Some chapter title',
                              item_title: 'foo')
    end.to raise_error(
      ActiveRecord::RecordInvalid, 'Validation failed: This item is not scannable'
    )
  end

  it 'allows scannable only materials to be requested for scan' do
    expect do
      described_class.create!(
        item_id: '123456',
        origin: 'SAL',
        origin_location: 'SAL-TEMP',
        section_title: 'Chapter 1',
        item_title: 'foo',
        bib_data: build(:scannable_only_holdings)
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
      expect(SubmitIlliadRequestJob).to receive(:perform_later)
      subject.submit!
    end

    context 'when the scan destination has a pseudopatron barcode' do
      let(:subject) do
        create(:scan, :with_holdings_barcodes, origin: 'SAL',
                                               origin_location: 'SAL-TEMP',
                                               bib_data: build(:scannable_only_holdings))
      end

      it 'submits the request to the ILS also' do
        expect(Request.ils_job_class).to receive(:perform_later)
        subject.submit!
      end
    end
  end

  describe 'send_approval_status!' do
    describe 'for library id users' do
      let(:subject) { create(:scan, :without_validations, user: create(:library_id_user), item_title: 'foo') }

      it 'does not send an approval status email' do
        expect do
          subject.send_approval_status!
        end.not_to have_enqueued_mail
      end
    end

    describe 'for everybody else' do
      let(:subject) { create(:scan, :without_validations, user: create(:sso_user), item_title: 'foo') }

      it 'sends an approval status email' do
        expect do
          subject.send_approval_status!
        end.to have_enqueued_mail(RequestStatusMailer)
      end
    end
  end
end
