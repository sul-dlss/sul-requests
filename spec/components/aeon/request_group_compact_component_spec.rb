# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::RequestGroupCompactComponent, type: :component do
  context 'with multi-item requests' do
    let(:web_request_form) { 'multiple' }
    let(:first_request) do
      build(:aeon_request, ead_number: 'SC0097', title: 'Donald E. Knuth papers',
                           transaction_number: 100, web_request_form:)
    end
    let(:second_request) do
      build(:aeon_request, ead_number: 'SC0097', title: 'Donald E. Knuth papers',
                           transaction_number: 101, web_request_form:)
    end
    let(:request_group) { Aeon::RequestGrouping.new([first_request, second_request]) }

    before do
      allow(first_request).to receive_messages(draft?: true, cancelled?: false)
      allow(second_request).to receive_messages(draft?: true, cancelled?: false)
      render_inline(described_class.new(request_group:))
    end

    it 'renders the request type' do
      expect(page).to have_content 'Reading room use'
    end

    it 'renders the call number' do
      expect(page).to have_content 'Call number: SC0097'
    end

    it 'renders the data-request-id for each request' do
      expect(page).to have_css '[data-request-id="100"]'
      expect(page).to have_css '[data-request-id="101"]'
    end

    it 'does not put data-request-id on the outer div' do
      expect(page).to have_no_css 'div.request-group[data-request-id]'
    end
  end

  context 'with a single-item request' do
    let(:request) do
      build(:aeon_request, call_number: 'SF442 .M439 1972', title: 'A single item')
    end
    let(:request_group) { Aeon::RequestGrouping.new([request]) }

    before do
      render_inline(described_class.new(request_group:))
    end

    it 'renders the request type' do
      expect(page).to have_content 'Reading room use'
    end

    it 'renders the call number' do
      expect(page).to have_content 'Call number: SF442 .M439 1972'
    end

    it 'has the request data-request-id' do
      expect(page).to have_css '[data-request-id="307"]'
    end

    it 'does not render the item list' do
      expect(page).to have_no_css 'ul'
    end
  end

  context 'with digitization requests' do
    let(:request) do
      build(:aeon_request, :digitized, title: 'Digital collection')
    end
    let(:request_group) { Aeon::RequestGrouping.new([request]) }

    before do
      render_inline(described_class.new(request_group:))
    end

    it 'renders the request type as digitization' do
      expect(page).to have_content 'Digitization'
    end
  end

  context 'with ead requests' do
    let(:request) do
      build(:aeon_request, call_number: 'SC0097 The Art of Computer Programming', ead_number: 'SC0097',
                           title: 'Donald E. Knuth papers')
    end
    let(:request_group) { Aeon::RequestGrouping.new([request]) }

    before do
      render_inline(described_class.new(request_group:))
    end

    it 'renders the ead number as the call number' do
      expect(page).to have_content 'Call number: SC0097'
    end
  end
end
