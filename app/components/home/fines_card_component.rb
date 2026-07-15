# frozen_string_literal: true

module Home
  # Fees & fines card for the card-view home page.
  class FinesCardComponent < ViewComponent::Base
    attr_reader :id, :title, :classes, :icon, :fines, :balance, :patron_key, :path, :past_path

    def initialize(id:, title:, icon:, fines:, balance:, patron_key:, path:, past_path:, classes: []) # rubocop:disable Metrics/ParameterLists
      @id = id
      @title = title
      @classes = classes
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
