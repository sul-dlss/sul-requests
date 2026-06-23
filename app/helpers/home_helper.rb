# frozen_string_literal: true

# Helpers for the home page redesign views.
module HomeHelper
  def count_callout(count:, phrase:)
    return unless count.to_i.positive?

    tag.span(safe_join([tag.span(count, class: 'fw-semibold'), phrase], ' '),
             class: 'text-digital-red-dark')
  end
end
