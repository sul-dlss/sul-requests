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
    Subseries = Data.define(:title, :contents)

    # This method can build 3 types of groups:
    # 1. ItemContainer: multiple items sharing the same top container (e.g., Box 9).
    # "container" is identified in Ead::Document by the presence of <container> elements and refers to physical containers.
    # 2. ItemWithoutContainer: These are leaf nodes in the EAD hierarchy that don't have a physical container.
    # 3. Subseries: This is an intellectual grouping in the EAD not tied to physical containers. Each subseries gets its own group.
    def build # rubocop:disable Metrics/AbcSize
      # Build display groups preserving original order
      @contents.group_by { |c| c.try(:top_container) || c.object_id }.each_value.map do |group|
        c = group.first

        if c.try(:top_container).present?
          ItemContainer.new(name: c.top_container, contents: group)
        elsif c.is_a?(Ead::Document::Item)
          ItemWithoutContainer.new(title: c.title)
        else
          Subseries.new(title: c[:title], contents: Ead::DisplayGroup.build_display_groups(c[:contents]))
        end
      end
    end
  end
end
