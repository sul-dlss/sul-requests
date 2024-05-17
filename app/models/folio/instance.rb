# frozen_string_literal: true

module Folio
  # Bibliographic data from Folio.
  class Instance
    class NotFound < StandardError; end

    def self.fetch(hrid)
      data = FolioClient.new.find_instance_by(hrid:)
      raise NotFound, "Instance hrid '#{hrid}' not found" unless data

      Folio::Instance.from_dynamic(data)
    end

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
        holdings_records: json.fetch('holdingsRecords', []).map { |hr| Folio::HoldingsRecord.from_hash(hr) }
      )
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
    def initialize(id:, hrid: '', title: '', contributors: [], pub_date: nil, pub_place: nil, publisher: nil, format: nil,
                   isbn: [], oclcn: [], electronic_access: [], edition: [], holdings_records: [])
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
      @holdings_records = holdings_records
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

    attr_reader :id, :pub_date, :pub_place, :publisher, :format

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
      @items ||= begin
        actual_items = holdings_records.flat_map(&:items)
        actual_items_ids = actual_items.map(&:id)
        bound_with_items = holdings_records.filter_map(&:bound_with_item).reject { |x| x.id.in? actual_items_ids }

        (actual_items + bound_with_items).reject(&:suppressed_from_discovery?)
      end
    end

    def holdings_records
      @holdings_records.reject(&:suppressed_from_discovery?)
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
