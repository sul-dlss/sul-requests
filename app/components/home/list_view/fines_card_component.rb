# frozen_string_literal: true

module Home
  module ListView
    # Fees & fines card for the list-view home page.
    class FinesCardComponent < ViewComponent::Base
      attr_reader :title, :icon, :fines, :balance, :patron_key, :path

      def initialize(title:, icon:, fines:, balance:, patron_key:, path:) # rubocop:disable Metrics/ParameterLists
        @title = title
        @icon = icon
        @fines = fines
        @balance = balance
        @patron_key = patron_key
        @path = path
      end

      def render? = balance.positive?
    end
  end
end
