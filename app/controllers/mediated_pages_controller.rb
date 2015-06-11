###
#  Controller to handle particular behaviors for MediatedPage type requests
###
class MediatedPagesController < RequestsController
  def current_request
    @mediated_page ||= MediatedPage.new
  end

  protected

  def validate_request_type
    fail UnmediateableItemError unless @mediated_page.mediateable?
  end

  class UnmediateableItemError < StandardError
  end
end
