require 'rails_helper'

describe Scan do
  it 'should have the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'Scan'
  end
end
