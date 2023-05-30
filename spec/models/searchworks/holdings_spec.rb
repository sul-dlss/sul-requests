# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchworks::Holdings do
  subject(:requested_holdings) { described_class.new(item.request, item.holdings) }

  before do
    allow(Request).to receive(:bib_model_class).and_return(SearchworksItem)
  end

  describe '#all' do
    describe 'items that exist' do
      let(:item) { build(:green_stacks_searchworks_item) }

      it 'are present for the requested location' do
        expect(subject.all).to be_a Array
        expect(subject.all.length).to eq 1
        expect(subject.all.first.barcode).to eq '12345678'
        expect(subject.all.first.callnumber).to eq 'ABC 123'
      end

      it 'adds the request_status object to the items' do
        expect(subject.all.first.request_status).to be_a ItemStatus
      end
    end

    describe 'items that do not exist' do
      let(:item) { build(:green_stacks_searchworks_item) }

      before do
        allow(item).to receive_messages(request: build(:request, origin: 'SAL3', origin_location: 'STACKS'))
      end

      it 'are not present for the requested location' do
        expect(subject.all).to eq([])
      end
    end
  end

  describe '#single_checked_out_item?' do
    subject(:requested_holdings) do
      described_class.new(request, holdings)
    end

    let(:request) { build(:request) }

    context 'when the holdings include a single checked out item' do
      let(:holdings) do
        [
          Searchworks::Holding.new('code' => 'BIOLOGY',
                                   'locations' =>
           [{ 'code' => 'STACKS',
              'items' =>
              [{ 'barcode' => '87654321',
                 'callnumber' => 'ABC 321',
                 'current_location' => { 'code' => 'CHECKEDOUT' },
                 'due_date' => '01/01/2015',
                 'type' => 'STKS',
                 'status' => { 'availability_class' => 'page', 'status_text' => 'Available' } }] }])
        ]
      end

      it { is_expected.to be_single_checked_out_item }
    end

    context 'when the holdings includes multiple items' do
      let(:holdings) do
        [
          Searchworks::Holding.new('code' => 'BIOLOGY',
                                   'locations' =>
             [{ 'code' => 'STACKS',
                'items' =>
                [{ 'barcode' => '12345678',
                   'callnumber' => 'ABC 123',
                   'type' => 'STKS',
                   'status' => { 'availability_class' => 'available', 'status_text' => 'Available' } },
                 { 'barcode' => '87654321',
                   'callnumber' => 'ABC 321',
                   'current_location' => { 'code' => 'CHECKEDOUT' },
                   'due_date' => '01/01/2015',
                   'type' => 'STKS',
                   'status' => { 'availability_class' => 'page', 'status_text' => 'Available' } }] }])
        ]
      end

      it { is_expected.not_to be_single_checked_out_item }
    end
  end

  describe '#where' do
    let(:item) { build(:green_stacks_multi_holdings_searchworks_item) }

    context 'when given an array of barcodes' do
      subject(:by_barcodes) { requested_holdings.where(barcodes: %w(3610512345678 3610587654321)) }

      it 'returns the items' do
        expect(by_barcodes).to be_a Array
        expect(by_barcodes.length).to eq 2
        expect(by_barcodes.first.barcode).to eq '3610512345678'
        expect(by_barcodes.last.barcode).to eq '3610587654321'
      end
    end

    context 'when given a single barcode' do
      subject(:by_barcodes) { requested_holdings.where(barcodes: ['12345679']) }

      it 'returns the items' do
        expect(by_barcodes).to be_a Array
        expect(by_barcodes.length).to eq 1
        expect(by_barcodes.first.barcode).to eq '12345679'
      end
    end

    context 'when the given barcode does not exist' do
      subject(:by_barcodes) { requested_holdings.where(barcodes: ['not-a-barcode']) }

      it { is_expected.to be_empty }
    end
  end
end
