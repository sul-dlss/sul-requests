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

  def render_fine_status
    fine_status_html(css_class: 'small fw-medium rounded-pill text-white bg-plum-light ready',
                     icon: 'sharp-error-24px',
                     text: fine.status_label)
  end

  def contact_path(*, **)
    '#'
  end

  def body_title
    case fine.nice_status
    when 'SUL library card'
      'Lost library card'
    else
      fine.title
    end
  end

  private

  def fine_status_html(text:, css_class: nil, icon: nil, accrued: 0)
    tag.span(class: css_class) do
      safe_join([text], ' ')
    end
  end
end
