# frozen_string_literal: true

# Component for rendering unapproved mediated requests
class MediatedRequestComponent < ViewComponent::Base
  with_collection_parameter :request

  attr_reader :request

  def initialize(request:)
    @request = request
    super()
  end
end
