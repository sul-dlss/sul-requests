# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pageable' do
  subject(:request) { build(:request) }

  describe '#pageable?' do
    context 'when the LibraryLocation is not mediatable or hold recallable' do
      let(:holdings_relationship) do
        double(:relationship, where: [], all: [], single_checked_out_item?: false, single_in_process_item?: false)
      end

      before do
        request.origin = 'GREEN'
        request.origin_location = 'STACKS'
        allow(HoldingsRelationshipBuilder).to receive(:build).and_return(holdings_relationship)
      end

      it { is_expected.to be_pageable }
    end

    it 'is false when the LibraryLocation is hold recallable' do
      request.requested_barcode = '3610512345678'
      expect(request).not_to be_pageable
    end

    it 'is false if the LibraryLocation is mediatable' do
      request.origin = 'SPEC-COLL'
      request.origin_location = 'STACKS'
      expect(request).not_to be_pageable
    end
  end
end
