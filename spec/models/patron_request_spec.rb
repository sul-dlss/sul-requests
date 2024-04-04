# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PatronRequest do
  subject(:request) { described_class.new(**attr) }

  let(:attr) { {} }

  describe '#barcode=' do
    it 'sets the barcodes attribute' do
      request.barcode = '1234567890'

      expect(request.barcodes).to eq(['1234567890'])
    end
  end
end
