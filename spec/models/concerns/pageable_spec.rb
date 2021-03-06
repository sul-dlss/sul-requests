# frozen_string_literal: true

require 'rails_helper'

describe 'Pageable' do
  subject(:request) { build(:request) }

  describe '#pageable?' do
    it 'is true if the LibraryLocation is not mediatable or hold recallable' do
      request.origin = 'GREEN'
      request.origin_location = 'STACKS'
      expect(request).to be_pageable
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
