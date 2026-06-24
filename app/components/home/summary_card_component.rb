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

    attr_reader :title, :label, :count, :path,
                :empty_path, :empty_link_label, :secondary_label

    # rubocop:disable Metrics/ParameterLists
    def initialize(title:, icon:, path:, count:, label: nil, secondary_label: nil, status: nil, empty_path: nil, empty_link_label: nil)
      # rubocop:enable Metrics/ParameterLists
      @title = title
      @icon = icon
      @count = count
      @label = label
      @secondary_label = secondary_label
      @path = path
      @status = status
      @empty_path = empty_path
      @empty_link_label = empty_link_label
    end

    def empty?
      count.to_i.zero?
    end

    def default_status
      @status
    end

    def default_icon
      render_icon(@icon)
    end

    def render_icon(icon)
      tag.i(class: "bi #{icon} text-60-black fs-4")
    end
  end
end
