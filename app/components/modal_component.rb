# frozen_string_literal: true

# Render modal
class ModalComponent < ViewComponent::Base
  attr_reader :id, :data

  renders_one :title
  renders_one :banner
  renders_one :body, ->(classes: %w[modal-body fw-normal], &block) { tag.div(class: classes, &block) }
  renders_one :footer, ->(classes: %w[modal-footer], &block) { tag.div(class: classes, &block) }

  def initialize(id:, data: {})
    @id = id
    @data = data
  end

  def title_id
    "title-#{id}"
  end
end
