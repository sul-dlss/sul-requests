# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserRequestAggregator do
  subject(:aggregator) { described_class.new(user) }

  let(:user) { instance_double(User, aeon: aeon_user) }
  let(:aeon_user) { instance_double(Aeon::User, requests: aeon_requests) }
  let(:aeon_requests) do
    [
      Aeon::Request.new(title: 'Older item', creation_date: 1.day.ago),
      Aeon::Request.new(title: 'Newer item', creation_date: Time.current)
    ]
  end

  describe '#all' do
    it 'returns requests sorted by created_at descending by default' do
      results = aggregator.all
      expect(results.map(&:title)).to eq(['Newer item', 'Older item'])
    end

    it 'returns requests sorted ascending when specified' do
      results = aggregator.all(direction: :asc)
      expect(results.map(&:title)).to eq(['Older item', 'Newer item'])
    end

    context 'when the user has no aeon account' do
      let(:aeon_user) { nil }

      it 'returns no requests' do
        expect(aggregator.all).to be_empty
      end
    end
  end
end
