# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediationHelper do
  describe '#current_location_for_mediated_item' do
    subject { current_location_for_mediated_item(item) }

    let(:item) { double(:item, home_location: 'MSS-30', barcode: '123456', home_location: 'MSS-30', current_location:) }

    context 'when the current and home locations match' do
      let(:current_location) { 'MSS-30' }

      it 'is an empty string' do
        expect(subject).to eq ''
      end
    end

    context 'when the current and home location differ' do
      let(:current_location) { 'ANYTHING-ELSE' }

      it 'is the current_location' do
        expect(subject).to eq current_location
      end
    end
  end
end
