# frozen_string_literal: true

module Home
  module ListView
    # Generic count-with-teaser card for the list-view home page.
    class SummaryCardComponent < ViewComponent::Base
      renders_one :items

      attr_reader :title, :icon, :count, :pill_noun, :view_all_label, :view_all_path, :status

      def initialize(title:, icon:, count:, view_all_label:, view_all_path:, pill_noun: 'total', status: nil) # rubocop:disable Metrics/ParameterLists
        @title = title
        @icon = icon
        @count = count
        @pill_noun = pill_noun
        @view_all_label = view_all_label
        @view_all_path = view_all_path
        @status = status
      end

      def render? = count.positive?
    end
  end
end
