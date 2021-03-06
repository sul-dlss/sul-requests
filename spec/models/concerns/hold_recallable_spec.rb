# frozen_string_literal: true

require 'rails_helper'

describe 'HoldRecallable' do
  subject(:request) { build(:request) }

  describe '#HoldRecallable?' do
    it 'is false by default' do
      expect(request).not_to be_hold_recallable
    end

    describe 'when a barcode is provided' do
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

    describe 'when INPROCESS' do
      it 'is true when the origin_location is INPROCESS' do
        request.origin_location = 'INPROCESS'
        expect(request).to be_hold_recallable
      end

      it 'is true when all the current locations are INPROCESS' do
        expect(request).to receive_messages(
          holdings: [
            double('holding', current_location: double('location', code: 'INPROCESS')),
            double('holding', current_location: double('location', code: 'INPROCESS')),
            double('holding', current_location: double('location', code: 'INPROCESS'))
          ]
        )

        expect(request).to be_hold_recallable
      end

      it 'is false when only some of the current locations are INPROCESS' do
        expect(request).to receive_messages(
          holdings: [
            double('holding', current_location: double('location', code: 'INPROCESS')),
            double('holding', current_location: double('location', code: 'ANOTHER-LOCATION'))
          ]
        )

        expect(request).not_to be_hold_recallable
      end
    end

    describe 'when ON-ORDER' do
      it 'is true when the origin_location is ON-ORDER' do
        request.origin_location = 'ON-ORDER'
        expect(request).to be_hold_recallable
      end

      it 'is true when the current location is ON-ORDER' do
        allow(request).to receive_messages(holdings: [
                                             double('holding', current_location: double('location', code: 'ON-ORDER'))
                                           ])

        expect(request).to be_hold_recallable
      end
    end

    context 'when MISSING' do
      it 'is true when the current_location is MISSING' do
        allow(request).to receive_messages(holdings: [
                                             double('holding', current_location: double('location', code: 'MISSING'))
                                           ])

        expect(request).to be_hold_recallable
      end
    end

    context 'when CHECKEDOUT' do
      it 'is true when there is a single checked out item' do
        allow(request).to receive_messages(
          holdings_object: double('holdings_object', single_checked_out_item?: true, all: [])
        )

        expect(request).to be_hold_recallable
      end

      it 'is false when there is are multiple items' do
        allow(request).to receive_messages(
          holdings_object: double('holdings_object', single_checked_out_item?: false, all: [])
        )

        expect(request).not_to be_hold_recallable
      end
    end
  end
end
