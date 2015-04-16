require 'rails_helper'

describe Scan do
  it 'should have the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'Scan'
  end
  it 'should validate based on if the item is scannable or not' do
    expect(-> { Scan.create!(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS') }).to raise_error(
      ActiveRecord::RecordInvalid, 'Validation failed: This item is not scannable'
    )
  end
end
