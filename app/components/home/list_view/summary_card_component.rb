# frozen_string_literal: true

module Home
  module ListView
    # Generic count-with-teaser card for the list-view home page.
    class SummaryCardComponent < ViewComponent::Base
      renders_one :icon, ->(icon:) { render_icon(icon) }
      renders_one :status, ->(&block) { tag.p(class: 'text-digital-red-dark', &block) }

      renders_one :items

      attr_reader :title, :count, :pill_noun, :view_all_label, :view_all_path

      def initialize(title:, icon_class:, count:, view_all_label:, view_all_path:, pill_noun: 'total') # rubocop:disable Metrics/ParameterLists
        @title = title
        @icon_class = icon_class
        @count = count
        @pill_noun = pill_noun
        @view_all_label = view_all_label
        @view_all_path = view_all_path
      end

      def default_icon
        render_icon(@icon_class)
      end

      def render_icon(icon)
        tag.i(class: "bi #{icon} text-60-black fs-4 me-3")
      end

      def render? = count.positive?
    end
  end
end
