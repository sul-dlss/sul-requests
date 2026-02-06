# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PatronRequestSearch do
  describe '#call' do
    subject { described_class.call({ request_type: ['Page'] }.with_indifferent_access) }

    before do
      create(:page_patron_request)
      create(:page_patron_request)
      create(:mediated_patron_request)
    end

    it { is_expected.to have_attributes(count: 2) }
  end
end
