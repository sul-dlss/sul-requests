# frozen_string_literal: true

module Ead
  ##
  # Organizes EAD items into display groups for rendering
  # Consolidates items by container and preserves original document order
  class DisplayGroup
    def self.build_display_groups(contents, hierarchy = [])
      new(contents, hierarchy).build
    end

    attr_reader :hierarchy

    def initialize(contents, hierarchy = [])
      @contents = contents || []
      @hierarchy = hierarchy
    end

    ItemContainer = Data.define(:title, :contents, :hierarchy)
    ItemWithoutContainer = Data.define(:title, :hierarchy)
    DigitalItem = Data.define(:title, :href, :hierarchy)
    Subseries = Data.define(:title, :contents, :hierarchy)

    def build
      @contents.group_by(&:coalesce_key).each_value.map do |group|
        build_group(group)
      end
    end

    private

    # This method can build 3 types of groups:
    # 1. ItemContainer: multiple items sharing the same top container (e.g., Box 9).
    # "container" is identified in Ead::Document by the presence of <container> elements and refers to physical containers.
    # 2. ItemWithoutContainer/DigitalItem: These are leaf nodes in the EAD hierarchy that don't have a physical container, but
    #    may be a digital item.
    # 3. Subseries: This is an intellectual grouping in the EAD not tied to physical containers. Each subseries gets its own group.
    def build_group(group)
      c = group.first

      if c.top_container
        ItemContainer.new(title: c.top_container, contents: group, hierarchy: hierarchy)
      elsif c.contents.any?
        build_hierarchical_group(c)
      else
        build_leaf_group(c)
      end
    end

    def build_hierarchical_group(node)
      if all_leaves_containerless?(node.contents)
        ItemContainer.new(title: node.full_title, contents: node.contents, hierarchy: hierarchy)
      else
        Subseries.new(title: node.full_title,
                      contents: Ead::DisplayGroup.build_display_groups(node.contents, hierarchy + [node.full_title]), hierarchy: hierarchy)
      end
    end

    def build_leaf_group(item)
      if item.respond_to?(:digital_only?) && item.digital_only?
        DigitalItem.new(title: item.full_title, href: item.extref_href, hierarchy: hierarchy)
      else
        ItemWithoutContainer.new(title: item.title, hierarchy: hierarchy)
      end
    end

    def all_leaves_containerless?(contents)
      contents.all? { |node| node.is_a?(Ead::Document::Item) && node.top_container.nil? }
    end
  end
end
