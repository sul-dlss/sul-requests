# frozen_string_literal: true

###
#  Controller to handle particular behaviors for Page type requests
###
class PagesController < RequestsController
  before_action :check_if_proxy_sponsor, only: :create

  protected

  def validate_request_type
    raise UnpageableItemError unless current_request.pageable?
  end

  class UnpageableItemError < StandardError
  end
  rescue_from PagesController::UnpageableItemError, with: :item_not_requestable
end
