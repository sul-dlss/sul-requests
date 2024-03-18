# frozen_string_literal: true

module Folio
  # Bibliographic data from Folio.
  class Instance
    class NotFound < StandardError; end

    # rubocop:disable Style/OptionalBooleanParameter
    def self.fetch(request, _live_lookup = true)
      # Append "a" to the item_id unless it already starts with a letter (e.g. "in00000063826")
      hrid = request.item_id.start_with?(/\d/) ? "a#{request.item_id}" : request.item_id
      data = FolioClient.new.find_instance_by(hrid:)
      raise NotFound, "Instance hrid '#{hrid}' not found" unless data

      Folio::Instance.from_dynamic(data)
    end

    def self.filter_parent_bound_withs(parent_bound_withs, hrid)
      return [] unless parent_bound_withs

      parent_bound_withs.flatten.compact.each do |bound_with_record|
        @filter_parent_bound_withs = bound_with_record.dig('instance', 'items').each.map do |item|
          boundwithhrids = item['boundWithHoldingsPerItem'].filter { |bw| bw.dig('instance', 'hrid') == hrid }.flatten
          update_item_fields(item, boundwithhrids.first) if boundwithhrids.present?
        end
      end
      @filter_parent_bound_withs.compact
    end

    def self.update_item_fields(item, holdings_record)
      item['originalEffectiveCallNumber'] = item['effectiveCallNumberComponents']['callNumber']
      item['effectiveCallNumberComponents']['callNumber'] = holdings_record['callNumber']
      item['volume'] = ''
      item['enumeration'] = ''
      item
    end

    def self.items(json)
      hrid = json.fetch('hrid', '')
      parent_bound_withs_all_holdings = parent_bound_withs(json)
      return json.fetch('items', []).map { |item| Folio::Item.from_hash(item) } unless parent_bound_withs_all_holdings.present? && hrid

      parent_bound_withs = parent_bound_withs_all_holdings.pluck('boundWithItem')
      items = filter_parent_bound_withs(parent_bound_withs, hrid)
      items += json['items'] if json['items']

      items.compact.map do |item|
        matching_bound_with = parent_bound_withs_all_holdings.find { |bound_with| bound_with['boundWithItem']['id'] == item['id'] }

        if matching_bound_with && matching_bound_with&.dig('boundWithItem', 'instance', 'hrid') != hrid
          parent = matching_bound_with&.dig('boundWithItem', 'instance')

          # TODO: This is silly. Once https://github.com/sul-dlss/sul-requests/pull/2030 is in, resolve for real.
          parent['items'].each do |item|
            item['effectiveCallNumberComponents']['callNumber'] = item['originalEffectiveCallNumber']
          end

          item['bound_with_parent'] = parent
        end

        matching_bound_with_items = matching_bound_with&.dig('boundWithItem', 'instance', 'items')&.find do |bound_with_item|
          bound_with_item['id'] == item['id']
        end
        matching_bound_with_holdings = matching_bound_with_items&.dig('boundWithHoldingsPerItem')

        item['bound_with_requested_instance_holdings'] = matching_bound_with_holdings&.select do |holding|
          holding&.dig('instance', 'hrid') == hrid
        end

        item['bound_with_other_instance_holdings'] = matching_bound_with_holdings&.reject do |holding|
          holding&.dig('instance', 'hrid') == hrid
        end

        Folio::Item.from_hash(item)
      end
    end

    def self.parent_bound_withs(json)
      json.fetch('holdingsRecords', []).filter { |holding| holding['boundWithItem'] }
    end

    def self.child_bound_withs(json)
      return unless json['items']

      json['items'].pluck('boundWithHoldingsPerItem').flatten.compact
    end
    # rubocop:enable Style/OptionalBooleanParameter

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def self.from_dynamic(json)
      new(
        id: json.fetch('id'),
        hrid: json.fetch('hrid', ''),
        title: json.fetch('title', ''),
        contributors: json.fetch('contributors', []),
        pub_date: json.fetch('publication', []).pick('dateOfPublication'),
        pub_place: json.fetch('publication', []).pick('place'),
        publisher: json.fetch('publication', []).pick('publisher'),
        format: json.dig('instanceType', 'name'),
        isbn: json.fetch('identifiers', []).filter_map do |identifier|
          identifier.fetch('value') if identifier.dig('identifierTypeObject', 'name') == 'ISBN'
        end,
        oclcn: json.fetch('identifiers', []).filter_map do |identifier|
          identifier.fetch('value') if identifier.dig('identifierTypeObject', 'name') == 'OCLC'
        end,
        electronic_access: json.fetch('electronicAccess', []),
        edition: json.fetch('editions', []),
        items: items(json),
        parent_bound_withs: parent_bound_withs(json),
        child_bound_withs: child_bound_withs(json)
      )
    end

    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
    def initialize(id:, hrid: '', title: '', contributors: [], pub_date: nil, pub_place: nil, publisher: nil, format: nil,
                   isbn: [], oclcn: [], electronic_access: [], edition: [], items: [], parent_bound_withs: [], child_bound_withs: [])
      @id = id
      @hrid = hrid
      @title = title
      @contributors = contributors
      @pub_date = pub_date
      @pub_place = pub_place
      @publisher = publisher
      @format = format
      @isbn = isbn
      @oclcn = oclcn
      @electronic_access = electronic_access
      @edition = edition
      @items = items
      @parent_bound_withs = parent_bound_withs
      @child_bound_withs = child_bound_withs
    end
    # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists

    TITLE_AUTHOR_DELIMITER = ' / '

    def title(delimiter: TITLE_AUTHOR_DELIMITER)
      @title.split(delimiter).first
    end

    def author
      contributor = @contributors.find { |contrib| contrib.fetch('primary') } || @contributors.first
      contributor&.fetch('name')
    end

    attr_reader :pub_date, :pub_place, :publisher, :format, :parent_bound_withs, :child_bound_withs

    def isbn
      @isbn.first
    end

    def oclcn
      return if @oclcn.blank?

      preferred_value = @oclcn.find { |value| value.start_with?('(OCoLC-M)') } || @oclcn.first

      preferred_value.sub(/^\(OCoLC-M\)\s*/, '').sub(/^\(OCoLC\)\s*/, '')
    end

    def edition
      @edition.join('; ')
    end

    def finding_aid
      @electronic_access.find do |access|
        access.fetch('materialsSpecification')&.match?(/Finding aid/i)
      end&.fetch('uri')
    end

    def request_holdings(request)
      Folio::Holdings.new(request, items)
    end

    def items
      @items.reject(&:suppressed_from_discovery?)
    end

    def holdings
      items
    end

    def finding_aid?
      finding_aid.present?
    end

    def view_url
      [Settings.searchworks_link, hrid].join('/')
    end

    def instance_id
      @id
    end

    def hrid
      @hrid.start_with?(/a\d/) ? @hrid.sub(/^a/, '') : @hrid
    end
  end
end
