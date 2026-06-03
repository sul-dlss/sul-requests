# frozen_string_literal: true

class RequestComponentPreview < ViewComponent::Preview
  layout 'lookbook'

  def default
    render RequestComponent.new(
      request: FactoryBot.build(:request),
      patron: FactoryBot.build(:sponsor_patron)
    )
  end
end
