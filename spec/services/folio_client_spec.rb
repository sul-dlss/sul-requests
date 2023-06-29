# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FolioClient do
  describe '#inspect' do
    subject { described_class.new.inspect }

    it { is_expected.not_to include 'pass' }
  end
end
