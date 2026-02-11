# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::Request do
  let(:aeon_client) { instance_double(AeonClient) }

  before do
    allow(AeonClient).to receive(:new).and_return(aeon_client)
  end

  describe '#appointment?' do
    it 'returns true when appointment_id is present' do
      request = build(:aeon_request)
      expect(request).to be_appointment
    end

    it 'returns false when appointment_id is absent' do
      request = build(:aeon_request, :without_appointment)
      expect(request).not_to be_appointment
    end
  end

  describe '#digital?' do
    it 'returns true when electronic delivery is specified' do
      request = build(:aeon_request, :digitized)
      expect(request).to be_digital
      expect(request).not_to be_physical
    end
  end

  describe '#physical?' do
    it 'returns true when shipping option is omitted' do
      request = build(:aeon_request, shipping_option: nil)
      expect(request).not_to be_digital
      expect(request).to be_physical
    end
  end

  describe '#draft?' do
    it 'returns true when the transaction queue is a draft queue' do
      draft_queue = Aeon::Queue.new(id: 5, queue_name: 'Awaiting User Review', queue_type: 'Transaction')
      allow(aeon_client).to receive(:find_queue).with(id: 5, type: :transaction).and_return(draft_queue)

      request = build(:aeon_request, transaction_status: 5)
      expect(request).to be_draft
    end

    it 'returns false when the transaction queue is not a draft queue' do
      non_draft_queue = Aeon::Queue.new(id: 8, queue_name: 'Awaiting Request Processing', queue_type: 'Transaction')
      allow(aeon_client).to receive(:find_queue).with(id: 8, type: :transaction).and_return(non_draft_queue)

      request = build(:aeon_request, transaction_status: 8)
      expect(request).not_to be_draft
    end
  end

  describe '#completed?' do
    it 'returns true when transaction queue is completed' do
      completed_queue = Aeon::Queue.new(id: 75, queue_name: 'Awaiting Item Reshelving', queue_type: 'Transaction')
      allow(aeon_client).to receive(:find_queue).with(id: 75, type: :transaction).and_return(completed_queue)
      allow(aeon_client).to receive(:find_queue).with(id: nil, type: :photoduplication).and_return(nil)

      request = build(:aeon_request, transaction_status: 75, photoduplication_status: nil)
      expect(request).to be_completed
    end

    it 'returns true when photoduplication queue is completed' do
      non_completed = Aeon::Queue.new(id: 8, queue_name: 'Awaiting Request Processing', queue_type: 'Transaction')
      completed = Aeon::Queue.new(id: 23, queue_name: 'Item Delivered', queue_type: 'Photoduplication')
      allow(aeon_client).to receive(:find_queue).with(id: 8, type: :transaction).and_return(non_completed)
      allow(aeon_client).to receive(:find_queue).with(id: 23, type: :photoduplication).and_return(completed)

      request = build(:aeon_request, transaction_status: 8, photoduplication_status: 23)
      expect(request).to be_completed
    end

    it 'returns false when no queue is completed' do
      non_completed = Aeon::Queue.new(id: 8, queue_name: 'Awaiting Request Processing', queue_type: 'Transaction')
      allow(aeon_client).to receive(:find_queue).with(id: 8, type: :transaction).and_return(non_completed)
      allow(aeon_client).to receive(:find_queue).with(id: nil, type: :photoduplication).and_return(nil)

      request = build(:aeon_request, transaction_status: 8, photoduplication_status: nil)
      expect(request).not_to be_completed
    end

    it 'persists recently completed digital requests as submitted' do
      completed_queue = Aeon::Queue.new(id: 75, queue_name: 'Awaiting Item Reshelving', queue_type: 'Transaction')
      allow(aeon_client).to receive(:find_queue).with(id: 75, type: :transaction).and_return(completed_queue)
      allow(aeon_client).to receive(:find_queue).with(id: nil, type: :photoduplication).and_return(nil)

      request = build(:aeon_request, :digitized,
                      transaction_status: 75,
                      photoduplication_status: nil,
                      transaction_date: 1.day.ago)
      expect(request).not_to be_completed
      expect(request).to be_submitted
    end

    it 'marks old completed digital requests as completed' do
      completed_queue = Aeon::Queue.new(id: 75, queue_name: 'Awaiting Item Reshelving', queue_type: 'Transaction')
      allow(aeon_client).to receive(:find_queue).with(id: 75, type: :transaction).and_return(completed_queue)
      allow(aeon_client).to receive(:find_queue).with(id: nil, type: :photoduplication).and_return(nil)

      request = build(:aeon_request, :digitized,
                      transaction_status: 75,
                      photoduplication_status: nil,
                      transaction_date: 10.days.ago)
      expect(request).to be_completed
      expect(request).not_to be_submitted
    end
  end

  describe '#submitted?' do
    it 'returns true when request is neither a draft or completed' do
      non_draft = Aeon::Queue.new(id: 8, queue_name: 'Awaiting Request Processing', queue_type: 'Transaction')
      allow(aeon_client).to receive(:find_queue).with(id: 8, type: :transaction).and_return(non_draft)
      allow(aeon_client).to receive(:find_queue).with(id: nil, type: :photoduplication).and_return(nil)

      request = build(:aeon_request, transaction_status: 8, photoduplication_status: nil)
      expect(request).to be_submitted
    end
  end

  describe '#scan_delivered?' do
    it 'returns true for a digital request in a completed queue' do
      completed_queue = Aeon::Queue.new(id: 75, queue_name: 'Awaiting Item Reshelving', queue_type: 'Transaction')
      allow(aeon_client).to receive(:find_queue).with(id: 75, type: :transaction).and_return(completed_queue)
      allow(aeon_client).to receive(:find_queue).with(id: nil, type: :photoduplication).and_return(nil)

      request = build(:aeon_request, :digitized, transaction_status: 75, photoduplication_status: nil)
      expect(request).to be_scan_delivered
    end

    it 'returns false for a physical request in a completed queue' do
      completed_queue = Aeon::Queue.new(id: 75, queue_name: 'Awaiting Item Reshelving', queue_type: 'Transaction')
      allow(aeon_client).to receive(:find_queue).with(id: 75, type: :transaction).and_return(completed_queue)
      allow(aeon_client).to receive(:find_queue).with(id: nil, type: :photoduplication).and_return(nil)

      request = build(:aeon_request, shipping_option: nil, transaction_status: 10, photoduplication_status: nil)
      expect(request).not_to be_scan_delivered
    end
  end
end
