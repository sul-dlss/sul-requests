# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HoldRecallable' do
  subject(:request) { build(:request) }

  let(:all) { [] }

  before do
    allow(HoldingsRelationshipBuilder).to receive(:build).and_return(all)
  end

  describe '#hold_recallable?' do
    context 'when a barcode is provided' do
      it 'is true' do
        request.requested_barcode = '3610512345'
        expect(request).to be_hold_recallable
      end

      it 'ignores empty barcodes' do
        request.requested_barcode = ''
        expect(request).not_to be_hold_recallable
        expect(request.requested_barcode).to be_nil
      end
    end

    context 'when all items are hold/recallable' do
      let(:all) do
        [
          double(:item, hold_recallable?: true),
          double(:item, hold_recallable?: true)
        ]
      end

      it 'is true' do
        expect(request).to be_hold_recallable
      end
    end

    context 'when some items are not hold/recallable' do
      let(:all) do
        [
          double(:item, hold_recallable?: true),
          double(:item, hold_recallable?: false)
        ]
      end

      it 'is false' do
        expect(request).not_to be_hold_recallable
      end
    end
  end
end
