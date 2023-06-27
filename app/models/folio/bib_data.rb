# frozen_string_literal: true

module Folio
  # Bibliographic data from Folio.
  class BibData
    TITLE_AUTHOR_DELIMITOR = ' / '
    def initialize(request, _ = nil)
      @request = request
    end

    attr_reader :request

    def title
      json.fetch('title', '').split(TITLE_AUTHOR_DELIMITOR).first
    end

    def author
      contributors = json.fetch('contributors', [])
      contributor = contributors.find { |contrib| contrib.fetch('primary') } || contributors.first
      contributor&.fetch('name')
    end

    def pub_date
      json.fetch('publication', []).pick('dateOfPublication')
    end

    def format
      type_id = json.fetch('instanceTypeId')
      return unless type_id

      type_labels = folio_client.instance_types.each_with_object({}) { |type, result| result[type['id']] = type['name'] }

      type_labels[type_id]
    end

    def isbn
      json.fetch('identifiers', []).filter_map do |identifier|
        identifier.fetch('value') if identifier.fetch('identifierTypeId') == Settings.folio.isbn_identifier_type
      end.join('; ')
    end

    def finding_aid
      json.fetch('electronicAccess', []).find do |access|
        access.fetch('materialsSpecification') == 'Finding aid available online'
      end&.fetch('uri')
    end

    def holdings
      json['holdings']
    end

    def finding_aid?
      finding_aid.present?
    end

    def view_url
      [Settings.searchworks_api, 'view', request.item_id].join('/')
    end

    def instance_id
      @instance_id ||= folio_client.resolve_to_instance_id(hrid:)
    end

    private

    # Append "a" to the item_id unless it already starts with a letter (e.g. "in00000063826")
    def hrid
      request.item_id.start_with?(/\d/) ? "a#{request.item_id}" : request.item_id
    end

    def json
      @json = folio_client.find_instance(instance_id:)
    end

    def folio_client
      FolioClient.new
    end
  end
end
