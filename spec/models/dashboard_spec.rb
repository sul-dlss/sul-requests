require 'rails_helper'

describe Dashboard do
  before do
    create(:mediated_page)
    create(:page)
    create(:page)
  end

  describe 'request type methods' do
    it 'should return the count of the different types of requests' do
      expect(subject.custom).to eq 0
      expect(subject.hold_recalls).to eq 0
      expect(subject.mediated_pages).to eq 1
      expect(subject.pages).to eq 2
      expect(subject.scans).to eq 0
    end
  end

  describe 'metrics' do
    it 'should return an array of metrics whose count is over 0' do
      expect(subject.metrics).to eq [:mediated_pages, :pages]
      create(:scan_with_holdings)
      expect(subject.class.new.metrics).to eq [:mediated_pages, :pages, :scans]
    end
  end

  describe 'recent requests' do
    before do
      create(:page)
      create(:page, origin: 'GREEN')
      create(:page, origin: 'SAL3')
    end
    it 'should return the recent request scope' do
      expect(subject.recent_requests(1, 50).map(&:id)).to eq Request.recent.map(&:id)
    end
  end
end
