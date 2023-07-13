# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SymphonyResponse do
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
  end

  describe '#all_successful?' do
    context 'when all the items were requested successfully' do
      subject { described_class.new(build(:symphony_page_with_multiple_items)) }

      it 'is true' do
        expect(subject.all_successful?).to be true
      end
    end

    context 'when some of the items fails' do
      it 'is false' do
        expect(subject.all_successful?).to be false
      end
    end
  end

  describe '#all_errored?' do
    context 'when all the items were requested successfully' do
      subject { described_class.new(build(:symphony_page_with_multiple_items)) }

      it 'is false' do
        expect(subject.all_errored?).to be false
      end
    end

    context 'when only some of the items failed' do
      it 'is false' do
        expect(subject.all_errored?).to be false
      end
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
end
