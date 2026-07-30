# frozen_string_literal: true

# Render a form
class RequestRgiFooter < ViewComponent::Base
  attr_reader :request_id, :date

  def initialize(date:, request_id: nil)
    @request_id = request_id
    @date = date
  end
end
