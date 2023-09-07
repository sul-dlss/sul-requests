# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pageable' do
  subject(:request) { build(:request) }

  describe '#pageable?' do
    context 'when the LibraryLocation is not mediatable or hold recallable' do
      before do
        request.location = 'SAL3-STACKS'
      end

      it { is_expected.to be_pageable }
    end

    context 'when the LibraryLocation is hold recallable' do
      before do
        request.requested_barcode = '3610512345678'
      end

      it { is_expected.not_to be_pageable }
    end

    context 'when the LibraryLocation is mediatable' do
      before do
        request.location = 'SPEC-STACKS'
      end

      it { is_expected.not_to be_pageable }
    end
  end
end
