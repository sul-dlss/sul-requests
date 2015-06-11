###
#  Controller to handle particular behaviors for Page type requests
###
class PagesController < RequestsController
  def current_request
    @page ||= Page.new
  end

  protected

  def validate_request_type
    fail UnpageableItemError unless @page.pageable?
  end

  class UnpageableItemError < StandardError
  end
end
