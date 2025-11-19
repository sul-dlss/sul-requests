# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PatronRequestSearch do
  describe '#call' do
    subject { described_class.call(ActionController::Parameters.new(request_type: ['Page'])) }

    before do
      mock_all = [build(:page_patron_request), build(:page_patron_request), build(:mediated_patron_request)]

      allow(PatronRequest).to receive(:all).and_return(mock_all)
    end

    it { is_expected.to have_attributes(length: 2) }
  end
end
