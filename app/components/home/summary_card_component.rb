# frozen_string_literal: true

module Home
  # Generic count-with-link card for the card-view home page.
  class SummaryCardComponent < ViewComponent::Base
    renders_one :icon, ->(icon:) { render_icon(icon) }
    renders_one :status, types: {
      next_up: lambda { |date:|
        if date
          tag.span(class: 'text-digital-red-dark') do
            tag.span('Next up: ') + tag.span(date.strftime('%b %-d, %Y'), class: 'fw-semibold')
          end
        end
      },
      count: lambda { |label:|
        tag.span(label, class: 'text-digital-red-dark') if label.present?
      },
      text: ->(text:) { text }
    }

    attr_reader :id, :title, :label, :link_label, :path, :secondary_label

    # rubocop:disable Metrics/ParameterLists
    def initialize(id:, title:, icon_class:, path:, label: nil, secondary_label: nil, status: nil, link_label: nil)
      # rubocop:enable Metrics/ParameterLists
      @id = id
      @title = title
      @icon_class = icon_class
      @label = label
      @secondary_label = secondary_label
      @path = path
      @status = status
      @link_label = link_label || 'View details'
    end

    def default_status
      @status
    end

    def default_icon
      render_icon(@icon_class)
    end

    def render_icon(icon_class)
      tag.i(class: "bi #{icon_class} text-60-black fs-4")
    end
  end
end
