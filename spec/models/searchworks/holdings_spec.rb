# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchworks::Holdings, if: Settings.ils.bib_model == 'SearchworksItem' do
  subject(:requested_holdings) { described_class.new(request, item.holdings) }

  describe 'items that exist' do
    let(:item) { build(:sal3_stacks_searchworks_item) }
    let(:request) { build(:request, origin: 'SAL3', origin_location: 'STACKS') }

    it 'are present for the requested location' do
      expect(subject.count).to eq 1
      expect(subject.first.barcode).to eq '12345678'
      expect(subject.first.callnumber).to eq 'ABC 123'
    end

    it 'adds the request_status object to the items' do
      expect(subject.first.request_status).to be_a ItemStatus
    end
  end

  describe 'items that do not exist' do
    let(:item) { build(:sal3_stacks_searchworks_item) }
    let(:request) { build(:request, origin: 'GREEN', origin_location: 'STACKS') }

    it 'are not present for the requested location' do
      expect(subject.count).to eq 0
    end
  end
end
