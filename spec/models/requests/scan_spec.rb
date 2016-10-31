require 'rails_helper'

describe Scan do
  it 'should have the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'Scan'
  end
  it 'should validate based on if the item is scannable or not' do
    expect do
      Scan.create!(item_id: '1234',
                   origin: 'GREEN',
                   origin_location: 'STACKS',
                   section_title: 'Some chapter title')
    end.to raise_error(
      ActiveRecord::RecordInvalid, 'Validation failed: This item is not scannable'
    )
  end

  describe 'requestable' do
    it { is_expected.not_to be_requestable_by_all }
    it { is_expected.not_to be_requestable_with_library_id }
    it { is_expected.to be_requestable_with_sunet_only }
    it { is_expected.not_to be_requires_additional_user_validation }
  end

  describe '#item_limit' do
    it 'is 1' do
      expect(subject.item_limit).to eq 1
    end
  end

  describe '#appears_in_myaccount?' do
    it 'is disabled' do
      expect(subject.appears_in_myaccount?).to be false
    end
  end

  describe 'item_commentable?' do
    it 'is false' do
      expect(subject).not_to be_item_commentable
    end
  end

  describe '#submit!' do
    it 'submits the request to Symphony immediately' do
      expect(SubmitSymphonyRequestJob).to receive(:perform_now)
      subject.submit!
    end
  end
end
