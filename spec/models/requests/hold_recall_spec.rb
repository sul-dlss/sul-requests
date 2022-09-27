# frozen_string_literal: true

require 'rails_helper'

describe HoldRecall do
  describe 'requestable' do
    it { is_expected.not_to be_requestable_with_name_email }
    it { is_expected.to be_requestable_with_library_id }
  end

  describe 'item_commentable?' do
    it 'is false' do
      expect(subject).not_to be_item_commentable
    end
  end

  it 'has the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'HoldRecall'
  end

  describe 'send_approval_status!' do
    describe 'for library id users' do
      let(:user) { create(:library_id_user) }
      let(:subject) { create(:hold_recall, user: user) }

      before do
        allow(Patron).to receive(:find_by).with(library_id: user.library_id).at_least(:once).and_return(
          double(exists?: true, email: nil)
        )
      end

      it 'does not send an approval status email' do
        expect do
          subject.send_approval_status!
        end.not_to change { RequestStatusMailer.deliveries.count }
      end
    end

    describe 'for everybody else' do
      let(:subject) { create(:hold_recall, user: create(:sso_user)) }

      it 'sends an approval status email' do
        expect do
          subject.send_approval_status!
        end.to change { RequestStatusMailer.deliveries.count }.by(1)
      end
    end
  end
end
