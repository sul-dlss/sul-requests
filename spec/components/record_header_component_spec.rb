# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecordHeaderComponent, type: :component do
  before do
    render_inline(described_class.new(record:))
  end

  context 'with aeon_request' do
    let(:record) { build(:aeon_request) }

    it 'shows the header with correct information' do
      expect(page).to have_css 'h2', text: 'Throwing a sinker ball at 94 mpg with wicked movement'
      expect(page).to have_text 'Document'
      expect(page).to have_link 'View in SearchWorks'
    end
  end

  context 'with folio_item with unspecified format' do
    let(:record) { build(:unspecified_not_on_order) }

    it 'shows the header with correct information' do
      expect(page).to have_css 'h2', text: 'Outline map of the Empire of Brazil and adjacent territories.'
      expect(page).to have_text 'Map'
      expect(page).to have_link 'View in SearchWorks'
    end
  end

  context 'with folio_item with format' do
    let(:record) { build(:single_holding_multiple_items) }

    it 'shows the header with correct information' do
      expect(page).to have_css 'h2', text: 'Multiple Items In Holding Title'
      expect(page).to have_text 'Book'
      expect(page).to have_link 'View in SearchWorks'
    end
  end

  context 'with ead_item' do
    let(:eadxml) { Nokogiri::XML(File.read('spec/fixtures/a0112.xml')).tap(&:remove_namespaces!) }
    let(:record) { Ead::Document.new(eadxml, url: 'whatever') }

    it 'shows the header with correct information' do
      expect(page).to have_css 'h2', text: 'Pehrson (Elmer Walter) Photograph Album'
      expect(page).to have_text 'Archive/Manuscript'
      expect(page).to have_link 'View in Archival Collections at Stanford'
    end
  end
end
