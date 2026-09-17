# frozen_string_literal: true

module Folio
  # Component for rendering the "Pay All" header + button
  class PayAllComponent < ViewComponent::Base
    attr_reader :patron, :fines

    def initialize(patron:, fines: nil)
      @patron = patron
      @fines = fines || @patron.fines
      super()
    end

    def amount
      @amount ||= fines.sum(&:owed)
    end

    def render?
      amount.positive?
    end
  end
end
