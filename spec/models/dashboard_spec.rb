# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard do
  before do
    allow_any_instance_of(FolioClient).to receive(:find_instance).and_return({ title: 'Test title' })
    allow_any_instance_of(FolioClient).to receive(:resolve_to_instance_id).and_return('f1c52ab3-721e-5234-9a00-1023e034e2e8')
    stub_folio_holdings(:folio_single_holding)
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
