# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::Request do
  describe '#appointment?' do
    it 'returns true when appointment_id is present' do
      request = described_class.new(appointment_id: 26)
      expect(request).to be_appointment
    end

    it 'returns false when appointment_id is absent' do
      request = described_class.new
      expect(request).not_to be_appointment
    end
  end
end
