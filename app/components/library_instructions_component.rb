# frozen_string_literal: true

# Display the instructions for the requested library
class LibraryInstructionsComponent < ViewComponent::Base
  def initialize(library_code:)
    @text = Settings.libraries[library_code]&.instructions
  end

  def render?
    text.present?
  end

  attr_reader :text
end
