# frozen_string_literal: true

class ModalComponentPreview < ViewComponent::Preview
  layout 'lookbook'

  def default
    render ModalComponent.new(id: 'xyz', classes: 'modal d-block')
  end
end
