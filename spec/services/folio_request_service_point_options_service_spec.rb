# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FolioRequestServicePointOptionsService do
  subject(:service) { described_class.new([item], patron:) }

  context 'with a location-restricted item for a guest' do
    let(:patron) { Folio::NullPatron.new }
    let(:item) { build(:page_mp_holdings).items.first }

    it 'allows the patron to select the location-restricted service point' do
      expect(service.possible_service_points.map(&:code)).to contain_exactly('EARTH-SCI')
    end
  end

  context 'with a regular circulating item for a guest' do
    let(:item) { build(:sal3_holding).items.first }
    let(:patron) { Folio::NullPatron.new }

    it 'requires the patron to select a service point they can access' do
      expect(service.possible_service_points.map(&:code)).to contain_exactly('GREEN-LOAN', 'ART', 'EAST-ASIA', 'MUSIC', 'LANE-DESK')
    end
  end
end
