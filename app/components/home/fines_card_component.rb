# frozen_string_literal: true

module Home
  # Fees & fines card for the card-view home page.
  class FinesCardComponent < ViewComponent::Base
    attr_reader :title, :icon, :fines, :balance, :patron_key, :path, :past_path

    def initialize(title:, icon:, fines:, balance:, patron_key:, path:, past_path:) # rubocop:disable Metrics/ParameterLists
      @title = title
      @icon = icon
      @fines = fines
      @balance = balance
      @patron_key = patron_key
      @path = path
      @past_path = past_path
    end

    def empty?
      balance.to_f.zero?
    end
  end
end
