# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FolioGraphqlClient do
  let(:client) { described_class.new }

  describe '#item_circulation_status' do
    it 'queries item IDs in bounded batches' do
      item_ids = Array.new(51) { |index| "item-#{index}" }
      allow(client).to receive(:item_circulation_status_batch).and_return([])

      client.item_circulation_status(item_ids:)

      expect(client).to have_received(:item_circulation_status_batch).with(item_ids.first(50)).ordered
      expect(client).to have_received(:item_circulation_status_batch).with(item_ids.last(1)).ordered
    end
  end

  describe '#hydrate_circulation_status' do
    let(:item) { build(:item, queue_length: 0) }
    let(:unchanged_item) { build(:item, queue_length: 3) }
    let(:circulation_status) do
      [
        {
          'id' => item.id,
          'queueTotalLength' => 2,
          'dueDate' => '2026-08-12T12:00:00.000+00:00'
        }
      ]
    end

    before do
      allow(client).to receive(:item_circulation_status).and_return(circulation_status)
    end

    it 'assigns returned circulation data to the matching items' do
      client.hydrate_circulation_status(items: [item, unchanged_item])

      expect(item).to have_attributes(queue_length: 2, due_date: 'Aug 12, 2026')
    end

    it 'does not overwrite items omitted from the response' do
      client.hydrate_circulation_status(items: [item, unchanged_item])

      expect(unchanged_item.queue_length).to eq 3
    end
  end
end
