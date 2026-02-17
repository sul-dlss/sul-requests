# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::Queue do
  describe '.from_dynamic' do
    let(:dyn) do
      {
        'id' => 5,
        'queueName' => 'Awaiting User Review',
        'displayName' => 'needs user review',
        'stateCode' => 25,
        'internalCode' => 25,
        'active' => true,
        'includeInRequestLimit' => false,
        'queueType' => 'Transaction'
      }
    end

    it 'parses API JSON into a Queue' do
      queue = described_class.from_dynamic(dyn)

      expect(queue).to have_attributes(
        id: 5,
        queue_name: 'Awaiting User Review',
        display_name: 'needs user review',
        state_code: 25,
        internal_code: 25
      )
      expect(queue).to be_active
      expect(queue).not_to be_include_in_request_limit
      expect(queue.type).to eq(:transaction)
    end
  end

  describe '#canceled?' do
    it 'returns true when queue_name is in the configured canceled list' do
      queue = described_class.new(id: 5, queue_name: 'Cancelled by User', queue_type: 'Transaction')
      expect(queue).to be_canceled
    end

    it 'returns false for a non-canceled queue' do
      queue = described_class.new(id: 8, queue_name: 'Awaiting Request Processing', queue_type: 'Transaction')
      expect(queue).not_to be_canceled
    end
  end

  describe '#draft?' do
    it 'returns true when queue_name is in the configured draft list' do
      queue = described_class.new(id: 5, queue_name: 'Awaiting User Review', queue_type: 'Transaction')
      expect(queue).to be_draft
    end

    it 'returns false for a non-draft queue' do
      queue = described_class.new(id: 8, queue_name: 'Awaiting Request Processing', queue_type: 'Transaction')
      expect(queue).not_to be_draft
    end
  end

  describe '#completed?' do
    it 'returns true for a completed transaction queue' do
      queue = described_class.new(id: 75, queue_name: 'Awaiting Item Reshelving', queue_type: 'Transaction')
      expect(queue).to be_completed
    end

    it 'returns true for a completed photoduplication queue' do
      queue = described_class.new(id: 23, queue_name: 'Item Delivered', queue_type: 'Photoduplication')
      expect(queue).to be_completed
    end

    it 'returns false for a non-completed queue' do
      queue = described_class.new(id: 11, queue_name: 'In Item Retrieval', queue_type: 'Transaction')
      expect(queue).not_to be_completed
    end
  end
end
