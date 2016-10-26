require 'rails_helper'

describe MediationHelper do
  describe '#current_location_for_mediated_item' do
    let(:item) { double(home_location: 'MSS-30', barcode: '123456') }
    subject { current_location_for_mediated_item(item) }
    before do
      location_object = double(current_location: current_location)
      expect(SymphonyCurrLocRequest).to receive(:new).with(barcode: '123456').and_return(location_object)
    end

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
