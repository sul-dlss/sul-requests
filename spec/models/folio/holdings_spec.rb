# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Holdings do
  subject(:holdings) { described_class.new(request, items) }

  let(:request) { HoldRecall.new(barcode: '36105237669143', item_id: '14820051', origin: 'MUSIC', origin_location: 'MUS-RECORDINGS') }
  let(:items) { [item] }
  let(:item) do
    Folio::Item.new(barcode: '123',
                    status: 'In process',
                    type: 'multimedia',
                    base_callnumber: 'XX(14820051.1)',
                    public_note: nil,
                    effective_location: instance_double(Folio::Location, details: {}),
                    permanent_location:)
  end

  describe 'Enumerable' do
    subject { holdings.to_a }

    context "when the request location doesn't match the effectiveLocation" do
      let(:permanent_location) { instance_double(Folio::Location, code: 'MUS-RECORDINGS') }

      it { is_expected.to eq items }
    end
  end

  context 'with searchworksTreatTemporaryLocationAsPermanentLocation set' do
    let(:item) do
      Folio::Item.new(barcode: '123',
                      status: 'Available',
                      type: 'multimedia',
                      base_callnumber: 'XX(14820051.1)',
                      public_note: nil,
                      effective_location: instance_double(
                        Folio::Location,
                        code: 'MUS-CRES',
                        details: {
                          'searchworksTreatTemporaryLocationAsPermanentLocation' => 'true'
                        }
                      ),
                      permanent_location: instance_double(Folio::Location, code: 'SAL3-STACKS'))
    end

    context 'for a request with the permanent location' do
      let(:request) { Page.new(item_id: '14820051', origin: 'SAL3', origin_location: 'SAL3-STACKS') }

      it 'excludes items with an effective location that does not match the requested location' do
        expect(holdings.to_a).to be_blank
      end
    end
  end
end
