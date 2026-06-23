# frozen_string_literal: true

# Component for rendering ILL requests
class IllRequestComponent < ViewComponent::Base
  with_collection_parameter :request

  attr_reader :request, :patron

  def initialize(request:, patron:)
    @request = request
    @patron = patron
    super()
  end
end
