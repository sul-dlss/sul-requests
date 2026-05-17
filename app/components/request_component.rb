# frozen_string_literal: true

# Component for rendering FOLIO requests
class RequestComponent < ViewComponent::Base
  attr_reader :request, :patron

  delegate :sul_icon, :detail_link_to_searchworks, to: :helpers

  def initialize(request:, patron:, group: false)
    @request = request
    @patron = patron
    @group = group
    super()
  end

  def group?
    @group
  end

  def cover_image
    identifiers = request.identifiers

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
