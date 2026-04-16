# frozen_string_literal: true

module Aeon
  # Render a group of requests that share the same title and request type
  class RequestGroupBriefWithButtonComponent < RequestGroupComponent
    with_collection_parameter :request_group
    def initialize(request_group:, remove: false)
      @remove = remove
      @request_group = request_group
    end

    def button_text
      @remove ? 'Remove' : 'Add'
    end

    def button_data(request)
      metadata = {title:, base_callnumber:, id: request.id, reading_room: request.reading_room&.name}
      return metadata.merge({action: 'click->add-items#removeFromForm'}) if @remove
      metadata.merge({action: 'click->add-items#addToForm'})
    end
  end
end
