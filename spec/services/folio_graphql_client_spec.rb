# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FolioGraphqlClient do
  describe '#instance' do
    let(:client) { described_class.new }
    let(:hrid) { 'a12345' }
    let(:instance_id) { 'fbb5d9bb-1c21-56f9-86ef-f95c0e67ff95' }
    let(:item_a) { '00068cd0-cd46-5e03-be75-1c1494665f89' }
    let(:item_b) { '0021a44b-5bfb-53e0-89e0-6c1a9a73d7e7' }
    let(:item_c) { '002facab-d4e6-5a6a-874c-320333025c63' }

    let(:instance_data) do
      {
        'id' => instance_id,
        'hrid' => hrid,
        'title' => 'Test Title',
        'holdingsRecords' => [{ 'items' => [{ 'id' => item_b, 'barcode' => '123' }, { 'id' => item_a, 'barcode' => '456' }],
                                'boundWithItem' => [{ 'id' => item_c, 'barcode' => '789' }] }]
      }
    end

    let(:availability_data) do
      [
        { 'id' => item_a, 'dueDate' => '2018-06-01T11:12:00Z' },
        { 'id' => item_b, 'dueDate' => nil },
        { 'id' => item_c, 'dueDate' => '2022-09-12T11:12:00Z' }
      ]
    end

    before do
      allow(client).to receive(:instance_data).with(hrid:).and_return(instance_data)
      allow(client).to receive(:availability).with(id: instance_id).and_return(availability_data)
    end

    it 'merges the due date from availability data (RTAC) into instance data' do
      data = client.instance(hrid:)
      items = data['holdingsRecords'][0]['items']
      expect(items).to include(hash_including('id' => item_a, 'dueDate' => '2018-06-01T11:12:00Z'))
      expect(items).to include(hash_including('id' => item_b, 'dueDate' => nil))
      expect(items).not_to include(hash_including('id' => item_c))

      bound_with_items = data['holdingsRecords'][0]['boundWithItem']
      expect(bound_with_items).to include(hash_including('id' => item_c, 'dueDate' => '2022-09-12T11:12:00Z'))
      expect(bound_with_items).not_to include(hash_including('id' => item_a))
      expect(bound_with_items).not_to include(hash_including('id' => item_b))
    end
  end
end
