# frozen_string_literal: true

# Render a single fine or payment for a patron
class FineComponent < ViewComponent::Base
  attr_reader :fine, :patron

  delegate :sul_icon, :detail_link_to_searchworks, to: :helpers

  def initialize(fine:, patron:)
    @fine = fine
    @patron = patron
    super()
  end

  def body_title
    case fine.nice_status
    when 'SUL library card'
      'Lost library card'
    else
      fine.title
    end
  end
end
