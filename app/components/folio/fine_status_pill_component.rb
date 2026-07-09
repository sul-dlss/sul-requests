# frozen_string_literal: true

module Folio
  # Render a pill with correct value/color combination based on fee status
  class FineStatusPillComponent < ViewComponent::Base
    attr_reader :status

    def initialize(status:)
      @status = status
      super()
    end

    def status_classes
      case fine_status
      when 'PAID'
        %w[fine-status bg-green text-green]
      else
        %w[fine-status bg-stanford-20-black text-black]
      end
    end

    def fine_status
      status.gsub('fully', '').strip.upcase
    end

    def call
      render PillComponent.new(classes: status_classes).with_content(fine_status)
    end
  end
end
