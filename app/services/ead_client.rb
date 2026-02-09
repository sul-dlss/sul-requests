# frozen_string_literal: true

# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/CyclomaticComplexity

require 'nokogiri'

##
# Service class for fetching and parsing EAD XML files
class EadClient
  attr_reader :url

  def initialize(url)
    @url = url
  end

  ##
  # Fetches the EAD XML from the provided URL and parses it
  # @return [Nokogiri::XML::Document] Parsed XML document
  def fetch_and_parse
    xml_content = fetch_xml
    parse_xml(xml_content)
  end

  ##
  # Fetches raw XML content from the URL
  # @return [String] Raw XML content
  def fetch_xml
    response = Faraday.get(url)

    raise "Failed to fetch EAD XML: HTTP #{response.code}" unless response.success?

    response.body
  rescue URI::InvalidURIError => e
    raise "Invalid URL provided: #{e.message}"
  rescue StandardError => e
    raise "Error fetching EAD XML: #{e.message}"
  end

  ##
  # Parses XML content using Nokogiri and removes namespace
  # @param xml_content [String] Raw XML string
  # @return [Nokogiri::XML::Document] Parsed XML document without namespace
  def parse_xml(xml_content)
    doc = Nokogiri::XML(xml_content)
    doc.remove_namespaces!
    doc
  rescue Nokogiri::XML::SyntaxError => e
    raise "Invalid XML format: #{e.message}"
  end

  ##
  # Extracts specific fields from the EAD XML
  # This is a placeholder for XSLT transformation
  # @return [Hash] Extracted data fields
  def extract_fields
    doc = fetch_and_parse

    {
      title: extract_title(doc),
      identifier: extract_identifier(doc),
      repository: extract_repository(doc),
      extent: extract_extent(doc),
      creator: extract_creator(doc),
      languages: extract_languages(doc),
      conditions_governing_use: extract_conditions_governing_use(doc),
      conditions_governing_access: extract_conditions_governing_access(doc),
      cite_as: extract_cite_as(doc),
      repository_contact: extract_repository_contact(doc),
      series_and_subseries: extract_series_and_subseries(doc),
      raw_xml: doc
    }
  end

  private

  def extract_title(doc)
    doc.xpath('//titleproper').first&.text&.strip
  end

  def extract_identifier(doc)
    doc.xpath('//unitid').first&.text&.strip
  end

  def extract_repository(doc)
    doc.xpath('//repository/corpname').first&.text&.strip
  end

  def extract_extent(doc)
    doc.xpath('//physdesc/extent').first&.text&.strip
  end

  def extract_creator(doc)
    # Try multiple XPaths for creator/origination
    doc.xpath('//origination/persname').first&.text&.strip ||
      doc.xpath('//origination/corpname').first&.text&.strip ||
      doc.xpath('//origination').first&.text&.strip
  end

  def extract_languages(doc)
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

    unique_languages.any? ? unique_languages.join(', ') : nil
  end

  def extract_conditions_governing_use(doc)
    doc.xpath('//userestrict/p').first&.text&.strip ||
      doc.xpath('//userestrict').first&.text&.strip
  end

  def extract_conditions_governing_access(doc)
    doc.xpath('//accessrestrict/p').first&.text&.strip ||
      doc.xpath('//accessrestrict').first&.text&.strip
  end

  def extract_cite_as(doc)
    # citation information
    doc.xpath('//prefercite/p').first&.text&.strip ||
      doc.xpath('//prefercite').first&.text&.strip
  end

  def extract_repository_contact(doc)
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

    contact_info.any? ? contact_info : nil
  end

  def extract_series_and_subseries(doc)
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
          containers: extract_containers(item_node),
          date: item_node.xpath('did/unitdate').first&.text&.strip,
          id: item_node.xpath('did/unitid').first&.text&.strip
        }
        series_data[:items] << item_data if item_data[:title]
      end

      series_list << series_data if series_data[:title]
    end

    series_list
  end

  def extract_containers(node)
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

# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/CyclomaticComplexity
