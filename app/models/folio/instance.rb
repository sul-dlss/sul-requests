# frozen_string_literal: true

module Folio
  # Bibliographic data from Folio.
  class Instance
    # rubocop:disable Style/OptionalBooleanParameter
    def self.fetch(request, _live_lookup = true)
      # Append "a" to the item_id unless it already starts with a letter (e.g. "in00000063826")
      hrid = request.item_id.start_with?(/\d/) ? "a#{request.item_id}" : request.item_id

      data = FolioClient.new.find_instance_by(hrid:)

      Folio::Instance.from_dynamic(data) if data
    end
    # rubocop:enable Style/OptionalBooleanParameter

    # rubocop:disable Metrics/MethodLength
    def self.from_dynamic(json)
      new(
        id: json.fetch('id'),
        hrid: json.fetch('hrid', ''),
        title: json.fetch('title', ''),
        contributors: json.fetch('contributors', []),
        pub_date: json.fetch('publication', []).pick('dateOfPublication'),
        format: json.dig('instanceType', 'name'),
        isbn: json.fetch('identifiers', []).filter_map do |identifier|
          identifier.fetch('value') if identifier.dig('identifierTypeObject', 'name') == 'ISBN'
        end,
        electronic_access: json.fetch('electronicAccess', []),
        items: json.fetch('items', []).map { |item| Folio::Item.from_hash(item) }
      )
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/ParameterLists
    def initialize(id:, hrid: '', title: '', contributors: [], pub_date: nil, format: nil, isbn: [], electronic_access: [], items: [])
      @id = id
      @hrid = hrid
      @title = title
      @contributors = contributors
      @pub_date = pub_date
      @format = format
      @isbn = isbn
      @electronic_access = electronic_access
      @items = items
    end
    # rubocop:enable Metrics/ParameterLists

    TITLE_AUTHOR_DELIMITER = ' / '

    def title(delimiter: TITLE_AUTHOR_DELIMITER)
      @title.split(delimiter).first
    end

    def author
      contributor = @contributors.find { |contrib| contrib.fetch('primary') } || @contributors.first
      contributor&.fetch('name')
    end

    attr_reader :pub_date, :format

    def isbn
      @isbn.join('; ')
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
