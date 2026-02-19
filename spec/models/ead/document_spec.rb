# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ead::Document do
  subject(:document) { described_class.new(eadxml) }

  let(:eadxml) do
    Nokogiri::XML(File.read('spec/fixtures/sc0097.xml')).tap(&:remove_namespaces!)
  end

  describe '#date' do
    it 'extracts the inclusive date' do
      expect(document.date).to eq('1962-2018')
    end
  end
end
