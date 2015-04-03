require 'rails_helper'

describe Custom do
  it 'should have the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'Custom'
  end
end
