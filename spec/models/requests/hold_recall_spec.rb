require 'rails_helper'

describe HoldRecall do
  describe 'requestable' do
    it { is_expected.not_to be_requestable_by_all }
    it { is_expected.to be_requestable_with_library_id }
    it { is_expected.not_to be_requestable_with_sunet_only }
  end

  describe 'item_commentable?' do
    it 'is false' do
      expect(subject).not_to be_item_commentable
    end
  end

  it 'should have the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'HoldRecall'
  end

  describe 'send_confirmation!' do
    let(:subject) { create(:hold_recall, user: create(:webauth_user)) }
    it 'returns true' do
      expect(
        -> { subject.send_confirmation! }
      ).not_to change { ConfirmationMailer.deliveries.count }
      expect(subject.send_confirmation!).to be true
    end
  end

  describe 'send_approval_status!' do
    describe 'for library id users' do
      let(:subject) { create(:hold_recall, user: create(:library_id_user)) }
      it 'does not send an approval status email' do
        expect(
          -> { subject.send_approval_status! }
        ).to_not change { ApprovalStatusMailer.deliveries.count }
      end
    end

    describe 'for everybody else' do
      let(:subject) { create(:hold_recall, user: create(:webauth_user)) }
      it 'sends an approval status email' do
        expect(
          -> { subject.send_approval_status! }
        ).to change { ApprovalStatusMailer.deliveries.count }.by(1)
      end
    end
  end
end
