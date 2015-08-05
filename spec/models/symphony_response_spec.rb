require 'rails_helper'

describe SymphonyResponse do
  describe '#items_by_barcode' do
    subject { described_class.new build(:symphony_scan_with_multiple_items) }

    it 'returns the items as a hash keyed by barcode' do
      expect(subject.items_by_barcode.length).to eq 3
      expect(subject.items_by_barcode.keys).to include '12345678901234', '12345678901234z', '36105212920537'
    end
  end
end
