# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::Request do
  before do
    allow(Aeon::Queue).to receive(:find_by) do |id: nil, **_kwargs|
      Aeon::Queue.from_dynamic(StubAeonClient::Queue.find_by(id: id).as_json) if id
    end
  end

  describe '#status' do
    subject(:request) do
      build(:aeon_request, transaction_status: queue.id)
    end

    let(:transaction_status) { nil }

    let(:queue) { Aeon::Queue.new(id: 0, queue_name: transaction_status, queue_type: 'Transaction') }

    before do
      allow(Aeon::Queue).to receive(:find_by).with(id: queue.id).and_return(queue)
    end

    context 'with a saved for later request' do
      let(:transaction_status) { 'Awaiting User Review' }

      it 'returns saved for later' do
        expect(request.status).to eq :saved_for_later
      end
    end

    context 'with a submitted request' do
      let(:transaction_status) { 'Awaiting Request Processing' }

      it 'returns submitted' do
        expect(request.status).to eq :submitted
      end
    end

    context 'with a cancelled request' do
      let(:transaction_status) { 'Cancelled by User' }

      it 'returns cancelled' do
        expect(request.status).to eq :cancelled
      end
    end

    context 'with a completed request' do
      let(:transaction_status) { 'Request Finished' }

      it 'returns cancelled' do
        expect(request.status).to eq :completed
      end
    end
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

  describe '#saved_for_later?' do
    it 'returns true when the transaction queue is a saved for later queue' do
      request = build(:aeon_request, transaction_status: 5)
      expect(request).to be_saved_for_later
    end

    it 'returns false when the transaction queue is not a saved for later queue' do
      request = build(:aeon_request, transaction_status: 8)
      expect(request).not_to be_saved_for_later
    end
  end

  describe '#completed?' do
    it 'returns true when transaction queue is completed' do
      request = build(:aeon_request, transaction_status: 17, photoduplication_status: nil)
      expect(request).to be_completed
    end

    it 'returns true when photoduplication queue is completed' do
      request = build(:aeon_request, transaction_status: 8, photoduplication_status: 23, shipping_option: 'Electronic Delivery')
      expect(request).to be_completed
    end

    it 'returns false when no queue is completed' do
      request = build(:aeon_request, transaction_status: 8, photoduplication_status: nil)
      expect(request).not_to be_completed
    end

    it 'persists recently completed digital requests as submitted' do
      request = build(:aeon_request, :digitized,
                      transaction_status: 17,
                      photoduplication_status: 23,
                      transaction_date: 1.day.ago)
      expect(request).not_to be_completed
      expect(request).to be_submitted
    end

    it 'marks old completed digital requests as completed' do
      request = build(:aeon_request, :digitized,
                      transaction_status: 17,
                      photoduplication_status: nil,
                      transaction_date: 10.days.ago)
      expect(request).to be_completed
      expect(request).not_to be_submitted
    end
  end

  describe '#submitted?' do
    it 'returns true when request is neither a saved for later or completed' do
      request = build(:aeon_request, transaction_status: 8, photoduplication_status: nil)
      expect(request).to be_submitted
    end
  end

  describe '#scan_delivered?' do
    it 'returns true for a digital request in a completed queue' do
      request = build(:aeon_request, :digitized, transaction_status: 17, photoduplication_status: 23)
      expect(request).to be_scan_delivered
    end

    it 'returns false for a physical request in a completed queue' do
      request = build(:aeon_request, shipping_option: nil, transaction_status: 10, photoduplication_status: nil)
      expect(request).not_to be_scan_delivered
    end
  end
end
