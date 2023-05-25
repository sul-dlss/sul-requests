# frozen_string_literal: true

# Display the instructions for the requested library
class LibraryInstructionsComponent < ViewComponent::Base
  def initialize(request:)
    @request = request
  end

  def render?
    @request.holdings_object.library_instructions.present?
  end

  def text
    @request.holdings_object.library_instructions[:text]
  end
end
