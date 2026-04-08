# frozen_string_literal: true

# Render modal
class ModalComponent < ViewComponent::Base
  attr_reader :id, :data

  renders_one :title
  renders_one :banner
  renders_one :body
  renders_one :footer

  def initialize(id:, data: {})
    @id = id
    @data = data
  end

  def title_id
    "title-#{id}"
  end
end
