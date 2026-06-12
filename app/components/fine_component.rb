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

  def checked_out?
    fine.is_a?(Folio::Checkout)
  end

  def accruing_rate_label
    rate = fine.overdue_fines_rate if checked_out?
    return unless rate

    "#{sul_icon('sharp-warning-24px')}Accruing #{number_to_currency(rate['quantity'])}/#{rate['intervalId']} until returned"
  end

  def body_title
    return fine.title if checked_out?

    case fine.nice_status
    when 'SUL library card'
      'Lost library card'
    else
      fine.title
    end
  end
end
