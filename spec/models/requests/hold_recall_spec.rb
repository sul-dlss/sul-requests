require 'rails_helper'

describe HoldRecall do
  it 'should have the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'HoldRecall'
  end
end
