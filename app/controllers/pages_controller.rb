###
#  Controller to handle particular behaviors for Page type requests
###
class PagesController < RequestsController
  protected

  def validate_request_type
    fail UnpageableItemError unless current_request.pageable?
  end

  class UnpageableItemError < StandardError
  end
end
