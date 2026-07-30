# frozen_string_literal: true

module System
  # Render a request grouping
  class GroupedRequestsLayoutComponent < ViewComponent::Base
    renders_one :type, types: {
      pill: ->(content:) { render PillComponent.new(classes: %w[bg-lagunita-dark text-white]).with_content(content) }
    }
    renders_one :details, lambda { |content|
      tag.span content, class: 'ms-2 ps-1 text-nowrap text-lagunita-dark'
    }

    renders_one :status_message

    renders_one :title
    renders_one :record_header

    renders_one :cover_image
    renders_many :requests

    attr_reader :id, :element, :attr

    def initialize(id:, element: 'li', show_more: false, sortable: false, **attr)
      @id = id
      @element = element
      @attr = attr

      @sortable = sortable
      @show_more = show_more
    end

    def sortable?
      @sortable
    end

    def show_more?
      @show_more
    end
  end
end
