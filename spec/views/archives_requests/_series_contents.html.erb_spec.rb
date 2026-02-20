# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'archives_requests/_series_contents.html.erb' do
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder, check_box: '') }
  let(:parent_title) { 'Test Series' }

  before do
    allow(view).to receive_messages(volume_value: '{}', volume_checkbox_id: 'test-checkbox-id', collapsible_content_id: 'test-content-id')
  end

  # rubocop:disable RSpec/ExampleLength
  context 'with container items' do
    it 'displays a collapsible container group with all items' do
      item1 = Ead::Document::Item.new(
        title: 'Item 1',
        level: 'file',
        containers: [{ type: 'Box', value: '9' }, { type: 'Folder', value: '1' }],
        date: nil,
        id: 'item-1'
      )
      item2 = Ead::Document::Item.new(
        title: 'Item 2',
        level: 'file',
        containers: [{ type: 'Box', value: '9' }, { type: 'Folder', value: '2' }],
        date: nil,
        id: 'item-2'
      )
      items = [item1, item2]
      display_groups = Ead::DisplayGroup.build_display_groups(items)

      render partial: 'archives_requests/series_contents',
             locals: { contents: display_groups, f: form_builder, parent_title: parent_title, series_title: parent_title }

      # Should have container label with badge showing count
      expect(rendered).to have_css('.form-check-label', text: 'Box 9')
      expect(rendered).to have_css('.badge', text: '2')

      # Should have collapsible content with folder list
      expect(rendered).to have_css('.collapse ul li', text: /Folder 1:\s+Item 1/)
      expect(rendered).to have_css('.collapse ul li', text: /Folder 2:\s+Item 2/)
    end
  end

  context 'with individual items (no container)' do
    it 'displays each item with its own checkbox' do
      item1 = Ead::Document::Item.new(
        title: 'Standalone Item 1',
        level: 'file',
        containers: [],
        date: nil,
        id: 'item-3'
      )
      item2 = Ead::Document::Item.new(
        title: 'Standalone Item 2',
        level: 'file',
        containers: [],
        date: nil,
        id: 'item-4'
      )
      items = [item1, item2]
      display_groups = Ead::DisplayGroup.build_display_groups(items)

      render partial: 'archives_requests/series_contents',
             locals: { contents: display_groups, f: form_builder, parent_title: parent_title, series_title: parent_title }

      # Should have individual checkboxes for each item
      expect(rendered).to have_css('.form-check-label', text: 'Standalone Item 1')
      expect(rendered).to have_css('.form-check-label', text: 'Standalone Item 2')

      # Should NOT have a collapsible container structure with badge
      expect(rendered).to have_no_css('.badge')
    end
  end

  context 'with subseries' do
    it 'displays a collapsible subseries header with recursive content' do
      subseries_items = [
        Ead::Document::Item.new(
          title: 'Subseries Item',
          level: 'file',
          containers: [{ type: 'Box', value: '1' }],
          date: nil,
          id: 'item-5'
        )
      ]

      subseries = {
        title: 'Subseries A',
        level: 'subseries',
        contents: subseries_items
      }
      items = [subseries]
      display_groups = Ead::DisplayGroup.build_display_groups(items)

      render partial: 'archives_requests/series_contents',
             locals: { contents: display_groups, f: form_builder, parent_title: parent_title, series_title: parent_title }

      # Should have subseries header with title and badge
      expect(rendered).to have_css('span', text: 'Subseries A')
      expect(rendered).to have_css('.badge', text: '1')

      # Should have collapse structure with chevron icon
      expect(rendered).to have_css('i.bi-chevron-right')
      expect(rendered).to have_css('.collapse')
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
