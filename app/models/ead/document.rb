# frozen_string_literal: true

# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/CyclomaticComplexity

module Ead
  ##
  # Model for parsing EAD XML files
  class Document
    attr_reader :url, :doc

    def initialize(doc, url: nil)
      @doc = doc
      @url = url
    end

    def title
      @title ||= doc.xpath('//titleproper').first&.text&.strip
    end

    def identifier
      @identifier ||= doc.xpath('//unitid[not(@type)]').first&.text&.strip
    end

    # Note, OAC populates this value with the archives.stanford.edu permalink
    # This means we aren't distinguishing/tracking traffic from OAC
    def collection_permalink
      @collection_permalink ||= doc.xpath('//eadid/@url').first&.value&.strip
    end

    def date
      @date ||= begin
        inclusive = doc.xpath('/ead/archdesc/did/unitdate[@type="inclusive"]').map { |x| x.text.strip }.join(', ')
        bulk = doc.xpath('/ead/archdesc/did/unitdate[@type="bulk"]').map { |x| x.text.strip }.join(', ')
        other = doc.xpath('/ead/archdesc/did/unitdate[not(@type)]').map { |x| x.text.strip }.join(', ')

        [inclusive, bulk, other].compact.reject(&:empty?).join(', ').presence
      end
    end

    def repository
      @repository ||= doc.xpath('//repository/corpname').first&.text&.strip
    end

    def extent
      @extent ||= doc.xpath('//physdesc/extent').first&.text&.strip
    end

    def creator
      # Try multiple XPaths for creator/origination
      @creator ||= doc.xpath('//origination/persname').first&.text&.strip ||
                   doc.xpath('//origination/corpname').first&.text&.strip ||
                   doc.xpath('//origination').first&.text&.strip
    end

    def languages
      return @languages if defined?(@languages)

      # Get all langmaterial elements, split by common delimiters, deduplicate
      lang_nodes = doc.xpath('//langmaterial')

      languages = lang_nodes.flat_map do |node|
        node.text.strip.split(/[;.,]\s*/)
      end

      # Remove empties, strip whitespace, deduplicate (case-insensitive), and sort
      unique_languages = languages
                         .map(&:strip)
                         .reject(&:empty?)
                         .uniq(&:downcase)

      @languages = unique_languages.any? ? unique_languages.join(', ') : nil
    end

    def conditions_governing_use
      @conditions_governing_use ||= doc.xpath('//userestrict/p').first&.text&.strip ||
                                    doc.xpath('//userestrict').first&.text&.strip
    end

    def conditions_governing_access
      @conditions_governing_access ||= doc.xpath('//accessrestrict/p').first&.text&.strip ||
                                       doc.xpath('//accessrestrict').first&.text&.strip
    end

    def cite_as
      # citation information
      @cite_as ||= doc.xpath('//prefercite/p').first&.text&.strip ||
                   doc.xpath('//prefercite').first&.text&.strip
    end

    def repository_contact
      return @repository_contact if defined?(@repository_contact)

      # Extract repository contact information from publicationstmt
      address_node = doc.xpath('//publicationstmt/address').first
      return nil unless address_node

      contact_info = {}
      address_lines = []

      # Extract addresslines
      address_node.xpath('addressline').each do |line|
        # Check if this line contains an extptr (website link)
        extptr = line.xpath('extptr').first
        if extptr
          contact_info[:website] = extptr['href'] || extptr['xlink:href']
          next
        end

        # Check if this line contains an email (has @ symbol)
        text = line.text.strip
        if text.include?('@')
          contact_info[:email] = text
        else
          address_lines << text unless text.empty?
        end
      end

      contact_info[:address] = address_lines if address_lines.any?

      @repository_contact = contact_info.any? ? contact_info : nil
    end

    def series_and_subseries
      return @series_and_subseries if defined?(@series_and_subseries)

      # Get top-level components (c01)
      c01_nodes = doc.xpath('//dsc/c01')

      @series_and_subseries = c01_nodes.filter_map do |c01_node|
        process_component(c01_node)
      end
    end

    # Recursively process a component node (c01, c02, c03, etc.)
    def process_component(node)
      level = node['level']

      # Build title with date
      title_text = node.xpath('did/unittitle').first&.text&.strip
      date_text = node.xpath('did/unitdate').first&.text&.strip
      full_title = [title_text, date_text].compact.reject(&:empty?).join(', ')

      return nil if full_title.empty?

      if hierarchical?(node)
        # This node is hierarchical (series/subseries) - process its immediate child components
        children = child_components(node)
        items_and_subseries = children.filter_map do |child_node|
          process_component(child_node)
        end

        {
          title: full_title,
          level: level || 'series',
          contents: items_and_subseries.compact
        }
      else
        # This is a leaf component (file-level item, possibly with physical containers)
        Item.new(
          title: title_text,
          level: level || 'file',
          containers: containers(node),
          date: date_text,
          id: node.xpath('did/unitid').first&.text&.strip
        )
      end
    end

    # This list is taken directly from Aeon's XSLT
    # It identifies container levels appropriate for request submission.
    PARENT_CONTAINER_TYPES = %w[
      Box Carton Case Folder Frame Object Page Reel Volume Half-Box Flat-Box
      Othertype Items Othercontainertype Computer_Media Drawer Bin Cassette
      Map-Case Tube Map-Folder Box-Folder Compact_Disc Audiocassette Model
      Oversize-Box Map-Tube Oversize-Folder Item Roll Tray Videodisc Oversize
      Card-Box Flatbox-Small Flatbox-Large Disc Binder
    ].freeze

    # Item is a leaf component that may belong inside physical containers (Box, Folder) but has no child components in the hierarchy
    Item = Data.define(:title, :level, :containers, :date, :id) do
      def box
        containers&.find { |c| c[:type] == 'Box' }&.dig(:value)
      end

      def folder
        containers&.find { |c| c[:type] == 'Folder' }&.dig(:value)
      end

      def top_container
        return nil unless containers

        top = containers.find { |c| PARENT_CONTAINER_TYPES.include?(c[:type]) }
        return nil unless top

        # e.g. Folder 1
        "#{top[:type]} #{top[:value]}"
      end
    end

    private

    def hierarchical?(node)
      # Check if this component is hierarchical (not a leaf node)
      # [series subseries recordgrp subgrp] check taken from old XSLT
      level = node['level']
      %w[series subseries recordgrp subgrp].include?(level) || child_components(node).any?
    end

    # child_components refers to immediate child/first descendents
    def child_components(node)
      node.xpath("./*[starts-with(name(), 'c0')]")
    end

    # all descendant c-level nodes (c01, c02, c03, etc.)
    def descendant_components(node)
      node.xpath('.//*[starts-with(name(), "c0")]')
    end

    # This refers to <container> elements within the <did> of leaf nodes
    def containers(node)
      # Extract container information (Box, Folder, etc.)
      containers = node.xpath('did/container').map do |container|
        {
          type: container['type']&.capitalize,
          value: container.text.strip
        }
      end
      containers.any? ? containers : nil
    end
  end
end

# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/CyclomaticComplexity
