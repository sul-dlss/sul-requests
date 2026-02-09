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
      @identifier ||= doc.xpath('//unitid').first&.text&.strip
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

      # Match components that are containers (series, subseries) or have child components
      series_list = []

      # Get top-level components (c01)
      c01_nodes = doc.xpath('//dsc/c01')

      c01_nodes.each do |c01_node|
        # Check if this is a container component (series, subseries, recordgrp, subgrp)
        # OR has child c0* nodes
        level = c01_node['level']
        has_children = c01_node.xpath('.//*[starts-with(name(), "c0")]').any?

        is_container = %w[series subseries recordgrp subgrp].include?(level) || has_children

        next unless is_container

        series_data = {
          title: c01_node.xpath('did/unittitle').first&.text&.strip,
          level: level || 'series',
          items: []
        }

        # Extract all descendant items (c02, c03, etc.) that are not containers
        c01_node.xpath('.//*[starts-with(name(), "c0")]').each do |item_node|
          item_level = item_node['level']
          item_has_children = item_node.xpath('.//*[starts-with(name(), "c0")]').any?
          item_is_container = %w[series subseries recordgrp subgrp].include?(item_level) || item_has_children

          # Only include leaf items (not containers)
          next if item_is_container

          item_data = {
            title: item_node.xpath('did/unittitle').first&.text&.strip,
            level: item_level,
            containers: containers(item_node),
            date: item_node.xpath('did/unitdate').first&.text&.strip,
            id: item_node.xpath('did/unitid').first&.text&.strip
          }
          series_data[:items] << item_data if item_data[:title]
        end

        series_list << series_data if series_data[:title]
      end

      @series_and_subseries = series_list
    end

    private

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
