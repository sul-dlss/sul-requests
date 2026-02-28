# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'archives_requests/_series_contents.html.erb' do
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder, check_box: '', object: instance_double(Ead::Request, items: [])) }
  let(:parent_title) { 'Test Series' }

  before do
    allow(view).to receive_messages(volume_value: '{}', volume_checkbox_id: 'test-checkbox-id', collapsible_content_id: 'test-content-id')
  end

  # rubocop:disable RSpec/ExampleLength
  context 'with container items' do
    it 'displays a collapsible container group with all items' do
      item1 = instance_double(Ead::Document::Item,
                              coalesce_key: 'Box 9',
                              top_container: 'Box 9',
                              folder: 'Folder 1',
                              full_title: 'Item 1',
                              title: 'Item 1',
                              level: 'file',
                              date: nil,
                              digital_content?: false,
                              id: 'item-1')
      item2 = instance_double(Ead::Document::Item,
                              coalesce_key: 'Box 9',
                              top_container: 'Box 9',
                              folder: 'Folder 2',
                              full_title: 'Item 2',
                              title: 'Item 2',
                              level: 'file',
                              date: nil,
                              digital_content?: false,
                              id: 'item-2')
      items = [item1, item2]
      display_groups = Ead::DisplayGroup.build_display_groups(items)

      render partial: 'archives_requests/series_contents',
             locals: { contents: display_groups, f: form_builder, parent_title: parent_title, series_title: parent_title, nested: false }

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
      item1 = instance_double(Ead::Document::Item,
                              coalesce_key: 1,
                              full_title: 'Standalone Item 1',
                              title: 'Standalone Item 1',
                              level: 'file',
                              top_container: nil,
                              contents: [],
                              date: nil,
                              id: 'item-3')
      item2 = instance_double(Ead::Document::Item,
                              coalesce_key: 2,
                              full_title: 'Standalone Item 2',
                              title: 'Standalone Item 2',
                              level: 'file',
                              top_container: nil,
                              contents: [],
                              date: nil,
                              id: 'item-4')
      items = [item1, item2]
      display_groups = Ead::DisplayGroup.build_display_groups(items)

      render partial: 'archives_requests/series_contents',
             locals: { contents: display_groups, f: form_builder, parent_title: parent_title, series_title: parent_title, nested: false }

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
        instance_double(Ead::Document::Item,
                        coalesce_key: 'Box 1',
                        full_title: 'Subseries Item',
                        title: 'Subseries Item',
                        level: 'file',
                        top_container: 'Box 1',
                        folder: nil,
                        date: nil,
                        digital_content?: false,
                        id: 'item-5')
      ]

      subseries = instance_double(Ead::Document::Node,
                                  coalesce_key: 1234,
                                  top_container: nil,
                                  full_title: 'Subseries A',
                                  title: 'Subseries A',
                                  date: nil,
                                  level: 'subseries',
                                  contents: subseries_items,
                                  id: nil)
      items = [subseries]
      display_groups = Ead::DisplayGroup.build_display_groups(items)

      render partial: 'archives_requests/series_contents',
             locals: { contents: display_groups, f: form_builder, parent_title: parent_title, series_title: parent_title, nested: false }

      # Should have subseries header with title and badge
      expect(rendered).to have_css('span', text: 'Subseries A')
      expect(rendered).to have_css('.badge', text: '1')

      # Should have collapse structure with chevron icon
      expect(rendered).to have_css('i.bi-chevron-right.disclosure-icon')
      expect(rendered).to have_css('.collapse')
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
