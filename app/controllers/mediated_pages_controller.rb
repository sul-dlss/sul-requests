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
      if current_user.webauth_user?
        redirect_to successfull_mediated_page_path(@mediated_page)
      else
        redirect_to successfull_mediated_page_path(@mediated_page, token: @mediated_page.encrypted_token)
      end
    else
      flash[:error] = 'There was a problem creating your request.'
      render 'new'
    end
  end

  protected

  def validate_mediated_pageable
    fail UnmediateableItemError unless @mediated_page.mediateable?
  end

  def rescue_can_can(*)
    if !current_user.webauth_user? && create_via_post?
      redirect_to login_path(
        referrer: create_mediated_pages_path(
          page: params[:mediated_page].except(:user_attributes)
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
                                          barcodes: [],
                                          data: [:comments],
                                          user_attributes: [:name, :email, :library_id])
  end

  def local_object_param
    params[:mediated_page]
  end

  class UnmediateableItemError < StandardError
  end
end
