# frozen_string_literal: true

require 'rails_helper'

describe LibraryHours do
  let(:library) { 'GREEN' }
  let(:subject) { described_class.new(library) }
  let(:today) { Time.zone.today }

  describe '#library' do
    context 'Non-scan library' do
      it 'returns the library' do
        expect(subject.send(:library)).to eq 'GREEN'
      end
    end

    context 'scanning library' do
      let(:library) { 'SCAN' }
      it 'proxies SCAN to GREEN' do
        expect(subject.send(:library)).to eq 'GREEN'
      end
    end
  end
end
