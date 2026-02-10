# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::Request do
  describe '#appointment?' do
    it 'returns true when appointment_id is present' do
      request = build(:aeon_request)
      expect(request).to be_appointment
    end

    it 'returns false when appointment_id is absent' do
      request = build(:aeon_request, :without_appointment)
      expect(request).not_to be_appointment
    end
  end
end
