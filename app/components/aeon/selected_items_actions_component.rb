# frozen_string_literal: true

module Aeon
  # Save for later, delete, list items buttons for form
  class SelectedItemsActionsComponent < ViewComponent::Base
    attr_reader :dom_id, :title

    def initialize(dom_id:, save_for_later:, title:)
      @dom_id = dom_id
      @save_for_later = save_for_later
      @title = title
    end

    def save_for_later?
      @save_for_later
    end
  end
end
