# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::RequestAbilities do
  subject(:abilities) { described_class.new(request) }

  let(:request) { instance_double(Request, holdings:) }
  let(:holdings) { [] }

  describe '#mediateable?' do
    context 'with an item in a mediated location' do
      let(:holdings) do
        [
          build(:item,
                barcode: '12345678',
                base_callnumber: 'ABC 123',
                permanent_location: build(:mediated_location))
        ]
      end

      it 'is mediateable' do
        expect(abilities.mediateable?).to be true
      end
    end

    context 'with an item in SAL3' do
      let(:holdings) do
        [
          build(:item,
                barcode: '12345678',
                base_callnumber: 'ABC 123',
                permanent_location: build(:location, code: 'SAL3-STACKS'))
        ]
      end

      it 'is not mediateable' do
        expect(abilities.mediateable?).to be false
      end
    end
  end

  describe '#aeon_pageable?' do
    context 'with an item in an aeon location' do
      let(:holdings) do
        [
          build(:item,
                barcode: '12345678',
                base_callnumber: 'ABC 123',
                permanent_location: build(:spec_coll_location))
        ]
      end

      it 'is aeon pageable' do
        expect(abilities.mediateable?).to be true
      end
    end

    context 'with an item in SAL3' do
      let(:holdings) do
        [
          build(:item,
                barcode: '12345678',
                base_callnumber: 'ABC 123',
                permanent_location: build(:location, code: 'SAL3-STACKS'))
        ]
      end

      it 'is not aeon pageable' do
        expect(abilities.mediateable?).to be false
      end
    end
  end

  describe '#pickup_destinations' do
    context 'with an item in an restricted location' do
      let(:holdings) do
        [
          build(:item,
                barcode: '12345678',
                base_callnumber: 'ABC 123',
                permanent_location: build(:page_lp_location))
        ]
      end

      it 'is pageable only to a couple locations' do
        expect(abilities.pickup_destinations).to contain_exactly 'MUSIC', 'MEDIA-CENTER'
      end
    end

    context 'with an item that is normally restricted with a temporary location somewhere else' do
      let(:holdings) do
        [
          build(:item,
                barcode: '12345678',
                base_callnumber: 'ABC 123',
                effective_location: build(:location, code: 'SAL3-STACKS'),
                permanent_location: build(:page_lp_location))
        ]
      end

      it 'is still pageable only to a couple locations' do
        expect(abilities.pickup_destinations).to contain_exactly 'MUSIC', 'MEDIA-CENTER'
      end
    end
  end
end
