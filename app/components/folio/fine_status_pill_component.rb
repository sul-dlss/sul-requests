# frozen_string_literal: true

module Folio
  # Render a pill with correct value/color combination based on fee status
  class FineStatusPillComponent < ViewComponent::Base
    attr_reader :fine

    def initialize(fine:)
      @fine = fine
      super()
    end

    def render?
      fine.closed?
    end

    def status_classes
      case status.upcase
      when 'PAID'
        %w[fine-status bg-green text-green text-uppercase]
      else
        %w[fine-status bg-stanford-20-black text-black text-uppercase]
      end
    end

    def status
      fine.status.split(' ', 2).first
    end

    def call
      render PillComponent.new(classes: status_classes).with_content(status)
    end
  end
end
