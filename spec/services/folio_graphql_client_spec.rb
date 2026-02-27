# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FolioGraphqlClient do
  describe '#instance' do
    let(:client) { described_class.new }
    let(:hrid) { 'a12345' }
    let(:instance_id) { 'fbb5d9bb-1c21-56f9-86ef-f95c0e67ff95' }
    let(:item_a) { '00068cd0-cd46-5e03-be75-1c1494665f89' }
    let(:item_b) { '0021a44b-5bfb-53e0-89e0-6c1a9a73d7e7' }
    let(:instance_queue_length) { 0 }
    let(:instance_data) do
      {
        'id' => instance_id,
        'hrid' => hrid,
        'title' => 'Test Title',
        'queueTotalLength' => instance_queue_length,
        'holdingsRecords' => [{ 'items' =>
                                [
                                  { 'id' => item_b, 'barcode' => '123' },
                                  { 'id' => item_a, 'barcode' => '456' }
                                ] }]
      }
    end

    context 'when the instance has a queueTotalLength of 0' do
      before do
        allow(client).to receive(:instance_data).with(hrid:).and_return(instance_data)
      end

      it 'sets queueTotalLength to 0 for all contained items without an additional query' do
        data = client.instance(hrid:)
        items = data['holdingsRecords'][0]['items']
        expect(items).to include(hash_including('id' => item_a, 'queueTotalLength' => 0))
        expect(items).to include(hash_including('id' => item_b, 'queueTotalLength' => 0))
      end
    end

    context 'when the instance has a non-zero queueTotalLength' do
      let(:instance_queue_length) { 3 }
      let(:items_queue_length_data) do
        {
          'holdingsRecords' => [{ 'items' =>
                                  [
                                    { 'id' => item_a, 'queueTotalLength' => 2 },
                                    { 'id' => item_b, 'queueTotalLength' => 1 }
                                  ] }]
        }
      end

      before do
        allow(client).to receive(:instance_data).with(hrid:).and_return(instance_data)
        allow(client).to receive(:items_queue_length).with(hrid:).and_return(items_queue_length_data)
      end

      it 'fetches and merges queueTotalLength for the items' do
        data = client.instance(hrid:)
        items = data['holdingsRecords'][0]['items']
        expect(items).to include(hash_including('id' => item_a, 'queueTotalLength' => 2))
        expect(items).to include(hash_including('id' => item_b, 'queueTotalLength' => 1))
      end
    end
  end
end
