# frozen_string_literal: true

# Render modal
class ModalComponent < ViewComponent::Base
  attr_reader :id, :data

  SIZES = { sm: 'modal-sm', lg: 'modal-lg', xl: 'modal-xl' }.freeze

  renders_one :title
  renders_one :banner
  renders_one :custom_header, ->(classes: %w[modal-header fw-normal], &block) { tag.div(class: classes, &block) }
  renders_one :body, ->(classes: %w[modal-body fw-normal], &block) { tag.div(class: classes, &block) }
  renders_one :footer, ->(classes: %w[modal-footer], &block) { tag.div(class: classes, &block) }

  def initialize(id:, size: nil, classes: %w[modal fade], header_classes: [], data: {})
    @id = id
    @size = size
    @data = data
    @classes = classes
    @header_classes = header_classes
  end

  def title_id
    "title-#{id}"
  end

  def dialog_classes
    ['modal-dialog', 'modal-dialog-centered', 'modal-dialog-scrollable', SIZES[@size]].compact
  end
end
