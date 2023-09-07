# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Holdings do
  subject(:holdings) { described_class.new(request, items) }

  let(:request) { HoldRecall.new(barcode: '36105237669143', item_id: '14820051', location: 'MUS-RECORDINGS') }
  let(:items) { [item] }
  let(:item) do
    Folio::Item.new(barcode: '123',
                    status: 'In process',
                    type: 'multimedia',
                    callnumber: 'XX(14820051.1)',
                    public_note: nil,
                    effective_location: instance_double(Folio::Location),
                    permanent_location:)
  end

  describe 'Enumerable' do
    subject { holdings.to_a }

    context "when the request location doesn't match the effectiveLocation" do
      let(:permanent_location) { instance_double(Folio::Location, code: 'MUS-RECORDINGS') }

      it { is_expected.to eq items }
    end
  end
end
