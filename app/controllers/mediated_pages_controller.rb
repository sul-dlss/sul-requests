###
#  Controller to handle particular behaviors for MediatedPage type requests
###
class MediatedPagesController < RequestsController
  def new
    request_defaults(@mediated_page)
    validate_mediated_pageable
  end

  def create
    if @mediated_page.update(create_params_with_current_user)
      @mediated_page.send_confirmation!
      redirect_to_success_with_token(@mediated_page)
    else
      flash[:error] = 'There was a problem creating your request.'
      render 'new'
    end
  end

  def current_request
    @mediated_page ||= MediatedPage.new
  end

  protected

  def validate_mediated_pageable
    fail UnmediateableItemError unless @mediated_page.mediateable?
  end

  def rescue_can_can(*)
    if !current_user.webauth_user? && create_via_post?
      redirect_to login_path(
        referrer: create_mediated_pages_path(
          mediated_page: local_object_param.except(:user_attributes)
        )
      )
    else
      super
    end
  end

  def create_params
    params.require(:mediated_page).permit(:destination,
                                          :item_id,
                                          :origin,
                                          :origin_location,
                                          :needed_date,
                                          :item_comment,
                                          :request_comment,
                                          barcodes: [],
                                          user_attributes: [:name, :email, :library_id])
  end

  def local_object_param
    params[:mediated_page]
  end

  class UnmediateableItemError < StandardError
  end
end
