# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediationHelper do
  describe '#current_location_for_mediated_item' do
    subject { current_location_for_mediated_item(item) }

    let(:item) do
      double(:item, barcode: '123456', permanent_location: build(:location, code: 'SPEC-MSS-20'),
                    temporary_location: build(:location, code: current_location))
    end

    context 'when the current and home locations match' do
      let(:current_location) { 'SPEC-MSS-20' }

      it 'is an empty string' do
        expect(subject).to eq ''
      end
    end

    context 'when the current and home location differ' do
      let(:current_location) { 'SAL3-STACKS' }

      it 'is the current_location' do
        expect(subject).to eq 'Location name'
      end
    end
  end
end
