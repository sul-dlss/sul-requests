# frozen_string_literal: true

module Folio
  # card on requests page for displaying requests grouped by catkey
  class RequestGroupComponent < ViewComponent::Base
    with_collection_parameter :request_group

    attr_reader :request_group, :patron

    delegate :detail_link_to_searchworks, to: :helpers

    def initialize(request_group:, patron:)
      @request_group = request_group
      @patron = patron
      super()
    end

    def cover_image
      identifiers = request_group.identifiers

      tag.img class: "cover-image center-block #{identifiers.values.flatten.join(' ')}",
              hidden: true,
              alt: '',
              data: {
                google_cover_image_target: 'image',
                isbn: identifiers['ISBN']&.join(','),
                oclc: identifiers['OCLC']&.join(','),
                lccn: identifiers['LCCN']&.join(',')
              }
    end
  end
end
