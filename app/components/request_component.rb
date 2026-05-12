# frozen_string_literal: true

# Component for rendering FOLIO requests
class RequestComponent < ViewComponent::Base
  attr_reader :request, :patron

  delegate :sul_icon, :detail_link_to_searchworks, to: :helpers

  def initialize(request:, patron:, group: false)
    @request = request
    @patron = patron
    @group = group
    super()
  end

  def group?
    @group
  end
end
