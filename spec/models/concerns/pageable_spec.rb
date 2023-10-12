# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pageable' do
  subject(:request) { build(:request) }

  describe '#pageable?' do
    context 'when the LibraryLocation is not mediatable or hold recallable' do
      before do
        request.origin = 'SAL3'
        request.origin_location = 'SAL3-STACKS'
      end

      it { is_expected.to be_pageable }
    end

    it 'is false when the LibraryLocation is hold recallable' do
      request.requested_barcode = '3610512345678'
      expect(request).not_to be_pageable
    end

    it 'is false if the LibraryLocation is mediatable' do
      request.origin = 'SPEC-COLL'
      request.origin_location = 'SPEC-STACKS'
      expect(request).not_to be_pageable
    end
  end
end
