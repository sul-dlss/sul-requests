# frozen_string_literal: true

# Helpers for the home page redesign views.
module HomeHelper
  def count_callout(label:)
    return if label.blank?

    tag.span(label, class: 'text-digital-red-dark')
  end
end
