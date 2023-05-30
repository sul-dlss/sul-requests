# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LibraryInstructionsComponent, type: :component do
  let(:rendered) { render_inline(described_class.new(library_code:)) }

  context 'when the library is has instructions' do
    let(:library_code) { 'EDUCATION' }

    it 'renders something useful' do
      expect(rendered.css('p.needed-date-info-block').to_html)
        .to include('The Education Library is closed for construction. Request items for pickup at another library.')
    end
  end

  context 'when the library has no instrutions' do
    let(:library_code) { 'GREEN' }

    it 'renders nothing' do
      expect(rendered.to_html).to be_empty
    end
  end
end
