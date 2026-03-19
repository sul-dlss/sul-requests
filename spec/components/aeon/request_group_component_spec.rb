# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::RequestGroupComponent, type: :component do
  let(:web_request_form) { 'multiple' }

  context 'with SearchWorks requests' do
    let(:first_request) do
      build(:aeon_request, call_number: 'PR9195.1 .S56 NO.1', title: 'Slow poetry in America : a poetry quarterly',
                           transaction_number: 100, web_request_form:)
    end
    let(:second_request) do
      build(:aeon_request, call_number: 'PR9195.1 .S56 NO.2', title: 'Slow poetry in America : a poetry quarterly',
                           transaction_number: 101, web_request_form:)
    end
    let(:request_group) { Aeon::RequestGrouping.new([first_request, second_request]) }

    before do
      allow(first_request).to receive_messages(draft?: true, cancelled?: false)
      allow(second_request).to receive_messages(draft?: true, cancelled?: false)
      render_inline(described_class.new(request_group:))
    end

    it 'renders information about each request' do
      expect(page).to have_css 'h2', text: 'Slow poetry in America : a poetry quarterly', count: 1
      expect(page).to have_content 'PR9195.1 .S56 NO.1'
      expect(page).to have_content 'PR9195.1 .S56 NO.2'
      expect(page).to have_content 'Request #100'
      expect(page).to have_content 'Request #101'
      expect(page).to have_no_content 'Call number:'
    end
  end

  context 'with submitted ead requests' do
    let(:first_request) do
      build(:aeon_request, call_number: 'SC0097 The Art of Computer Programming', ead_number: 'SC0097',
                           title: 'Donald E. Knuth papers', transaction_number: 100, volume: 'Box 1', web_request_form:)
    end
    let(:second_request) do
      build(:aeon_request, call_number: 'SC0097 The Art of Computer Programming', ead_number: 'SC0097',
                           title: 'Donald E. Knuth papers', transaction_number: 101, volume: 'Box 2', web_request_form:)
    end
    let(:request_group) { Aeon::RequestGrouping.new([first_request, second_request]) }

    before do
      allow(first_request).to receive_messages(cancelled?: false, completed?: false, draft?: false, submitted?: true)
      allow(second_request).to receive_messages(cancelled?: false, completed?: false, draft?: false, submitted?: true)
      render_inline(described_class.new(request_group:))
    end

    it 'renders information about each request' do
      expect(page).to have_css 'h2', text: 'Donald E. Knuth papers', count: 1
      expect(page).to have_content 'The Art of Computer Programming', count: 2
      expect(page).to have_content 'Mar 11, 2024', count: 2
      expect(page).to have_content '1 pm - 1:15 pm (PDT)', count: 2
      expect(page).to have_content 'SC0097', count: 1
      expect(page).to have_content 'Box 1'
      expect(page).to have_content 'Box 2'
      expect(page).to have_content 'Request #100'
      expect(page).to have_content 'Request #101'
    end
  end
end
