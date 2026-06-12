# frozen_string_literal: true

# Component for rendering FOLIO requests
class BorrowDirectRequestComponent < ViewComponent::Base
  attr_reader :borrow_direct_request

  delegate :sul_icon, to: :helpers

  def initialize(borrow_direct_request:)
    @borrow_direct_request = borrow_direct_request

    super()
  end

  def group?
    @group
  end
end
