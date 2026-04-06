# frozen_string_literal: true

# Render modal
class ModalComponent < ViewComponent::Base
  attr_reader :id, :data, :submit_text, :cancel_text

  renders_one :title
  renders_one :body
  renders_one :prepend_body

  def initialize(id:, data: {}, submit_text: 'Submit', cancel_text: 'Cancel')
    @id = id
    @data = data
    @submit_text = submit_text
    @cancel_text = cancel_text
  end

  def form_id
    "form-#{id}"
  end

  def title_id
    "title-#{id}"
  end
end
