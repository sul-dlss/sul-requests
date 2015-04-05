require 'rails_helper'

describe MediatedPage do
  it 'should have the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'MediatedPage'
  end
end
