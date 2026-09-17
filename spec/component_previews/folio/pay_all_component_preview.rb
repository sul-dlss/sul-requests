# frozen_string_literal: true

module Folio
  class PayAllComponentPreview < ViewComponent::Preview
    layout 'lookbook'

    def default
      render Folio::PayAllComponent.new(
        patron: FactoryBot.build(:patron_with_fines)
      )
    end
  end
end
