# frozen_string_literal: true

module System
  # Render a delete button with confirmation modal
  class GoogleCoverImageComponent < ViewComponent::Base
    attr_reader :identifiers

    def initialize(identifiers:)
      @identifiers = identifiers
    end

    def call
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
