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

  def validate_patron_standing
    return unless Settings.features.validate_patron_standing
    return unless current_user.patron.blocked?

    redirect_to polymorphic_path(
      [:blocked, current_request],
      request_context_params.merge(origin: current_request.origin)
    )
  end

  class UnpageableItemError < StandardError
  end
end
