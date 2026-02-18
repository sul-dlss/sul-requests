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

    # rubocop:disable Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
    # This method can build 3 types of groups:
    # 1. :item_container: multiple items sharing the same top container (e.g., Box 9).
    # "container" is identified in Ead::Document by the presence of <container> elements and refers to physical containers.
    # 2. :individual_item: These are leaf nodes in the EAD hierarchy that don't have a physical container.
    # 3. :subseries: This is an intellectual grouping in the EAD not tied to physical containers. Each subseries gets its own group.
    def build
      return [] if @contents.empty?

      # Separate contents by type
      contents_by_type = @contents.group_by { |item| item.is_a?(Ead::Document::Item) ? :item : :subseries }
      leaf_items = contents_by_type[:item] || []

      items_within_containers = leaf_items.select { |item| item.top_container.present? }
      # Create a lookup
      grouped_by_container = items_within_containers.group_by(&:top_container)

      # Build display groups preserving original order
      display_groups = []
      seen_keys = Set.new

      @contents.each do |c|
        if c.is_a?(Ead::Document::Item)
          if c.top_container.present?
            # Item is in a container - consolidate with all other items in same container
            container_name = c.top_container
            next if seen_keys.include?(container_name)

            seen_keys.add(container_name)

            display_groups << { type: :item_container, name: container_name, contents: grouped_by_container[container_name] }
          else
            # Item has no container - add individually
            display_groups << { type: :individual_item, item: c }
          end
        else
          # Subseries - use object_id for uniqueness
          key = [:subseries, c.object_id]
          next if seen_keys.include?(key)

          seen_keys.add(key)

          display_groups << { type: :subseries, data: c }
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity

      display_groups
    end
  end
end
