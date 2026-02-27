# frozen_string_literal: true

module Ead
  ##
  # Organizes EAD items into display groups for rendering
  # Consolidates items by container and preserves original document order
  class DisplayGroup
    def self.build_display_groups(contents)
      new(contents).build
    end

    def initialize(contents)
      @contents = contents || []
    end

    ItemContainer = Data.define(:name, :contents)
    ItemWithoutContainer = Data.define(:title)
    DigitalItem = Data.define(:title, :href)
    Subseries = Data.define(:title, :contents)

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
        ItemContainer.new(name: c.top_container, contents: group)
      elsif c.contents.any?
        Subseries.new(title: c.full_title, contents: Ead::DisplayGroup.build_display_groups(c.contents))
      else
        build_leaf_group(c)
      end
    end

    def build_leaf_group(item)
      if item.respond_to?(:digital_only?) && item.digital_only?
        DigitalItem.new(title: item.full_title, href: item.extref_href)
      else
        ItemWithoutContainer.new(title: item.title)
      end
    end
  end
end
