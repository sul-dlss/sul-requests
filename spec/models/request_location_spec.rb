# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestLocation do
  describe '#library' do
    subject { request_location.library }

    let(:request_location) { described_class.new(location) }
    let(:location) { 'GRE-STACKS' }

    it { is_expected.to eq 'GREEN' }
  end
end
