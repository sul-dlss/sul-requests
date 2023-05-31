# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard do
  let(:holdings_relationship) { double(:relationship, where: [], all: [], single_checked_out_item?: false) }

  before do
    allow(HoldingsRelationshipBuilder).to receive(:build).and_return(holdings_relationship)
    create(:mediated_page)
    create(:page)
    create(:page)
  end

  describe 'request type methods' do
    it 'returns the count of the different types of requests' do
      expect(subject.hold_recalls).to eq 0
      expect(subject.mediated_pages).to eq 1
      expect(subject.pages).to eq 2
      expect(subject.scans).to eq 0
    end
  end

  describe 'metrics' do
    it 'returns an array of metrics whose count is over 0' do
      expect(subject.metrics).to eq [:mediated_pages, :pages]
      create(:scan, :with_holdings)
      expect(subject.class.new.metrics).to eq [:mediated_pages, :pages, :scans]
    end
  end

  describe 'recent requests' do
    before do
      create(:page)
      create(:page, origin: 'GREEN')
      create(:page, origin: 'SAL3')
    end

    it 'returns the recent request scope' do
      expect(subject.recent_requests(1, 50).map(&:id)).to eq Request.recent.map(&:id)
    end
  end
end
