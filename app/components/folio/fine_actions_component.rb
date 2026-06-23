# frozen_string_literal: true

module Folio
  # Render the fine amount
  class FineActionsComponent < ViewComponent::Base
    attr_reader :fine

    def initialize(fine:)
      @fine = fine
    end

    def call
      tag.div(class: 'h4 mb-0') do
        number_to_currency(fine.owed.nonzero? || fine.fee)
      end
    end
  end
end
