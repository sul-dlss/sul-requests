# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'patron_requests/_ead_series_contents.html.erb' do
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder, check_box: '', object: instance_double(PatronRequest, selected_items: [])) }
  let(:parent_title) { 'Test Series' }
  let(:ead_doc) { Ead::Document.new(doc, url: 'https://test.com') }
  let(:display_groups) { Ead::DisplayGroup.build_display_groups(ead_doc.series_and_subseries) }

  before do
    allow(PatronRequest).to receive(:ead_doc).and_return(ead_doc)
    assign(:patron_request, PatronRequest)
  end

  context 'with single item, no series' do
    let(:doc) { Nokogiri::XML(File.read('spec/fixtures/a0112.xml')).tap(&:remove_namespaces!) }

    it 'displays a collapsible container group with all items' do
      render partial: 'patron_requests/ead_series_contents',
             locals: { contents: display_groups, f: form_builder, parent_title: parent_title, series_title: parent_title, nested: false }

      # Should have container label with badge showing count
      expect(rendered).to have_css('.form-check-label', text: 'Box 1')
      expect(rendered).to have_css('.badge', text: '1')
      expect(rendered).to have_field('patron_request[aeon_item][a0112_aspace_ref8_cg9_box-1][id]', disabled: true, type: 'hidden')

      # Should have collapsible content with folder list
      expect(rendered).to have_css('.collapse ul li', text: /Photograph Album/)
    end
  end

  context 'with individual items (no container)',
          skip: "right now we don't have an actual working view for this so skipping until it is fixed." do
    let(:doc) { Nokogiri::XML(File.read('spec/fixtures/ars0052.xml')).tap(&:remove_namespaces!) }

    it 'displays each item with its own checkbox' do
      render partial: 'patron_requests/ead_series_contents',
             locals: { contents: display_groups, f: form_builder, parent_title: parent_title, series_title: parent_title, nested: false }

      # Should have individual checkboxes for each item
      expect(rendered).to have_css('.form-check-label', text: 'Box 1')
      expect(rendered).to have_css('.form-check-label', text: 'Box 2')

      # Should NOT have a collapsible container structure with badge
      expect(rendered).to have_no_css('.badge')
    end
  end

  context 'with cartons and boxes mix' do
    let(:doc) { Nokogiri::XML(File.read('spec/fixtures/m1802.xml')).tap(&:remove_namespaces!) }

    it 'displays each item with its own checkbox' do
      render partial: 'patron_requests/ead_series_contents',
             locals: { contents: display_groups, f: form_builder, parent_title: parent_title, series_title: parent_title, nested: false }

      # Should have individual checkboxes for each item
      expect(rendered).to have_css('.form-check-label', text: 'Carton 1')
      expect(rendered).to have_css('.form-check-label', text: 'Awards honoring Jorge Chino')

      expect(rendered).to have_field(
        'patron_request[aeon_item][m1802_aspace_4abed5b8676d36189286e21d66656296_awards-honoring-jorge-chino][id]',
        disabled: true, type: 'hidden'
      )
    end
  end

  context 'with digital items' do
    let(:doc) { Nokogiri::XML(File.read('spec/fixtures/sc0838.xml')).tap(&:remove_namespaces!) }

    it 'displays each item with its own checkbox' do
      render partial: 'patron_requests/ead_series_contents',
             locals: { contents: display_groups, f: form_builder, parent_title: parent_title, series_title: parent_title, nested: false }

      # Should have individual checkboxes for each item
      expect(rendered).to have_css('.series-title', text: 'Businesses')
      expect(rendered).to have_css('.form-check-label', text: 'Box Map case Sc1 - rolled')

      expect(rendered).to have_link('Auto Electric Co. Battery Service Station, Hamilton Ave. Alma St., Palo Alto, California',
                                    href: 'https://archives.stanford.edu/findingaid/ark:/22236/s1366596f4-2e82-4ced-90df-ccb6c3794856')
    end
  end

  context 'when ead has mixed series and container levels' do
    let(:doc) { Nokogiri::XML(File.read('spec/fixtures/ars0036.xml')).tap(&:remove_namespaces!) }

    it 'displays series and subseries correctly' do
      render partial: 'patron_requests/ead_series_contents',
             locals: { contents: display_groups, f: form_builder, parent_title: parent_title, series_title: parent_title, nested: false }

      # Single level series
      expect(rendered).to have_css('.series-title', text: 'Open Reel Tape')
      within '#subseries-open-reel-tape-0' do
        expect(rendered).to have_css('.form-check-label', text: 'Box 1')
        expect(rendered).to have_field('patron_request[aeon_item][ars0036_aspace_ref48_rju_box-1][id]', disabled: true, type: 'hidden')
      end

      # nested series
      expect(rendered).to have_css('.series-title', text: 'Music scores, 1886-2007')
      within '#subseries-music-scores-1886-2007-6' do
        expect(rendered).to have_css('.series-header', text: 'John Sheridan 7 Piece Band')
        within '#subseries-music-scores-1886-2007-john-sheridan-7-piece-band-0' do
          expect(rendered).to have_css('.form-check-label', text: 'Box 37')

          expect(rendered).to have_field('patron_request[aeon_item][ars0036_aspace_6a0913a3d3de0fc276319a5ba5a0b1f8_box-37][id]',
                                         disabled: true, type: 'hidden')
        end
      end

      # no series
      expect(rendered).to have_field('patron_request[aeon_item][ars0036_aspace_ref21_8qi_box-25][id]', disabled: true, type: 'hidden')
    end
  end

  context 'with subseries' do
    let(:doc) { Nokogiri::XML(File.read('spec/fixtures/sc0097.xml')).tap(&:remove_namespaces!) }

    it 'displays a collapsible subseries header with recursive content' do
      render partial: 'patron_requests/ead_series_contents',
             locals: { contents: display_groups, f: form_builder, parent_title: parent_title, series_title: parent_title, nested: false }

      # Should have subseries header with title and badge
      expect(rendered).to have_css('span', text: 'Legal size documents')
      expect(rendered).to have_css('.badge', text: '1')
      expect(rendered).to have_field('patron_request[aeon_item][sc0097_aspace_ref303_6yp_box-12][id]', disabled: true, type: 'hidden')

      # Should have collapse structure with chevron icon
      expect(rendered).to have_css('i.bi-chevron-right.disclosure-icon')
      expect(rendered).to have_css('.collapse')
    end
  end

  context 'with no ids minted in ead' do
    let(:doc) { Nokogiri::XML(File.read('spec/fixtures/no_ids.xml')).tap(&:remove_namespaces!) }

    it 'mints an id using the hierarchy' do
      render partial: 'patron_requests/ead_series_contents',
             locals: { contents: display_groups, f: form_builder, parent_title: parent_title, series_title: parent_title, nested: false }

      # Should have container label with badge showing count
      expect(rendered).to have_css('.form-check-label', text: 'Box 1')
      expect(rendered).to have_css('.badge', text: '1')
      expect(rendered).to have_field('patron_request[aeon_item][volumes_box-1][id]', disabled: true, type: 'hidden')

      # Should have collapsible content with folder list
      expect(rendered).to have_css('.collapse ul li', text: /Photograph Album/)
    end
  end
end
