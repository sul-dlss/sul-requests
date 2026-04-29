# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::RequestGrouping do
  let(:aeon_client) { instance_double(AeonClient) }
  let(:queue) { Aeon::Queue.new(id: 0, queue_name: '', queue_type: 'Transaction') }

  before do
    allow(AeonClient).to receive(:new).and_return(aeon_client)
    allow(aeon_client).to receive(:find_queue).and_return(queue)
  end

  describe '.from_requests' do
    context 'with multiple item selector requests' do
      let(:reading_room_a) { build(:aeon_request, title: 'Title A', transaction_number: 1, web_request_form: 'multiple') }
      let(:reading_room_a2) { build(:aeon_request, title: 'Title A', transaction_number: 2, web_request_form: 'multiple') }
      let(:reading_room_b) { build(:aeon_request, title: 'Title B', transaction_number: 3, web_request_form: 'multiple') }
      let(:digital_a) { build(:aeon_request, :digitized, title: 'Title A', transaction_number: 4, web_request_form: 'multiple') }

      it 'groups requests by title and request type' do
        groups = described_class.from_requests([reading_room_a, reading_room_a2, reading_room_b, digital_a])

        expect(groups.count).to eq(3)
      end

      it 'groups same-title reading room requests together' do
        groups = described_class.from_requests([reading_room_a, reading_room_a2, reading_room_b])
        title_a_group = groups.find { |g| g.title == 'Title A' }

        expect(title_a_group.count).to eq(2)
        expect(title_a_group.requests).to contain_exactly(reading_room_a, reading_room_a2)
      end

      it 'keeps digitization and reading room requests with the same title separate' do
        groups = described_class.from_requests([reading_room_a, digital_a])

        expect(groups.count).to eq(2)
        expect(groups.map(&:digital?)).to contain_exactly(true, false)
      end
    end

    context 'with requests that do not use the item selector' do
      let(:single_a) { build(:aeon_request, title: 'Title A', transaction_number: 1, web_request_form: 'single') }
      let(:single_a2) { build(:aeon_request, title: 'Title A', transaction_number: 2, web_request_form: 'single') }

      it 'does not group the requests even with the same title' do
        groups = described_class.from_requests([single_a, single_a2])

        expect(groups.count).to eq(2)
        expect(groups.map(&:count)).to all(eq(1))
      end
    end

    context 'with a mix of item selector and single requests' do
      let(:multi_a) { build(:aeon_request, title: 'Title A', transaction_number: 1, web_request_form: 'multiple') }
      let(:multi_a2) { build(:aeon_request, title: 'Title A', transaction_number: 2, web_request_form: 'multiple') }
      let(:single_a) { build(:aeon_request, title: 'Title A', transaction_number: 3, web_request_form: 'single') }

      it 'groups item selector requests and keeps single requests separate' do
        groups = described_class.from_requests([multi_a, multi_a2, single_a])

        expect(groups.count).to eq(2)
        multi_group = groups.find { |g| g.count == 2 }
        expect(multi_group.requests).to contain_exactly(multi_a, multi_a2)
      end
    end
  end

  describe '#status_request' do
    context 'when the group is not digital' do
      let(:request) { build(:aeon_request) }
      let(:grouping) { described_class.new([request]) }

      it 'returns the first request' do
        expect(grouping.status_request).to eq(request)
      end
    end

    context 'when the group is digital and submitted with a mix of ready and pending' do
      let(:delivered) { build(:aeon_request, :digitized) }
      let(:pending) { build(:aeon_request, :digitized) }
      let(:grouping) { described_class.new([delivered, pending]) }

      before do
        allow(delivered).to receive_messages(submitted?: true, scan_delivered?: true)
        allow(pending).to receive_messages(submitted?: true, scan_delivered?: false)
      end

      it 'returns the pending request' do
        expect(grouping.status_request).to eq(pending)
      end
    end
  end
end
