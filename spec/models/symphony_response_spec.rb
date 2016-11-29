require 'rails_helper'

describe SymphonyResponse do
  subject { described_class.new build(:symphony_scan_with_multiple_items) }

  describe '#items_by_barcode' do
    it 'returns the items as a hash keyed by barcode' do
      expect(subject.items_by_barcode.length).to eq 3
      expect(subject.items_by_barcode.keys).to include '12345678901234', '12345678901234z', '36105212920537'
    end
  end

  describe '#success?' do
    it 'determines the success of a particular item when passed a barcode' do
      allow(subject).to receive_messages(usererr_code: nil)
      expect(subject.success?('12345678901234')).to be true
      expect(subject.success?('12345678901234z')).to be false
    end

    it 'is true when there is a usererr_code' do
      allow(subject).to receive_messages(usererr_code: 'abc')
      expect(subject).not_to be_success
    end

    it 'determines the success of all items when a barcode has not been supplied' do
      expect(subject).not_to be_success
    end
  end

  describe 'mixed_status?' do
    it 'returns true when there are both successful and unsuccessful items' do
      expect(subject.mixed_status?).to be true
    end

    it 'returns false when there is not a mix of items' do
      subject = described_class.new(build(:symphony_page_with_multiple_items))
      expect(subject.mixed_status?).to be false
    end
  end

  describe 'any_error?' do
    it 'returns true when there is a user error' do
      allow(subject).to receive_messages(usererr_code: 'abc')
      expect(subject.any_error?).to be true
    end

    it 'returns true when there is any item error' do
      expect(subject.any_error?).to be true
    end

    it 'returns false when all items are successful' do
      subject = described_class.new(build(:symphony_page_with_multiple_items))
      expect(subject.any_error?).to be false
    end
  end

  describe 'item_failed?' do
    it 'is false when the item was successful' do
      expect(subject.item_failed?('12345678901234')).to be false
    end

    it 'is true when the item has a non-successful status code' do
      expect(subject.item_failed?('12345678901234z')).to be true
    end
  end
end
