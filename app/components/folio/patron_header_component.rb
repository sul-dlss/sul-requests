# frozen_string_literal: true

module Folio
  # Component for rendering patron information
  class PatronHeaderComponent < ViewComponent::Base
    attr_reader :patron

    delegate to: :helpers

    def initialize(patron:)
      @patron = patron
      super()
    end

    def render?
      patron.present?
    end

    delegate :blocked?, to: :patron
  end
end
