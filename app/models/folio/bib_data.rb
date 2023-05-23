# frozen_string_literal: true

module Folio
  # Bibliographic data from Folio.
  class BibData
    def initialize(request, _ = nil)
      @request = request
    end

    attr_reader :request

    def title
      json.fetch('indexTitle', '')
    end

    def author
      json.fetch('contributors', []).map { |contrib| contrib.fetch('name') }.join('; ')
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
      return [] if json['holdings'].blank?

      @holdings ||= JSON.parse(json['holdings'].to_json)
    end

    def requested_holdings
      @requested_holdings ||= RequestedHoldings.new(self)
    end

    def finding_aid?
      finding_aid.present?
    end

    def view_url
      [Settings.searchworks_api, 'view', request.item_id].join('/')
    end

    private

    # Stub class for holdings. To be completed before done.
    class RequestedHoldings
      def initialize(bib_data)
        @bib_data = bib_data
      end

      def where(*); end

      def all
        []
      end
    end

    def json
      hrid = "a#{request.item_id}"
      folio_client.find_instance(hrid: hrid)
    end

    def folio_client
      FolioClient.new
    end
  end
end
