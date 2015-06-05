require 'rails_helper'

describe HoldRecall do
  describe 'requestable' do
    it { is_expected.not_to be_requestable_by_all }
    it { is_expected.to be_requestable_with_library_id }
    it { is_expected.not_to be_requestable_with_sunet_only }
  end

  it 'should have the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'HoldRecall'
  end
end
