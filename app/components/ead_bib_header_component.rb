# frozen_string_literal: true

# Render a card showing the bibliographic information for an EAD document
class EadBibHeaderComponent < ViewComponent::Base
  def initialize(ead:)
    @ead = ead
  end
end
