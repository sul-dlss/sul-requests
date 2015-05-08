###
#  Controller to handle particular behaviors for Page type requests
###
class PagesController < RequestsController
  def new
    request_defaults(@page)
    validate_pageable
  end

  def create
    if @page.update(create_params_with_current_user)
      if current_user.webauth_user?
        redirect_to successfull_page_path(@page)
      else
        redirect_to successfull_page_path(@page, token: @page.encrypted_token)
      end
    else
      flash[:error] = 'There was a problem creating your request.'
      render 'new'
    end
  end

  def update
    if @page.update(update_params)
      flash[:success] = 'Request was successfully updated.'
      redirect_to root_url
    else
      flash[:error] = 'There was a problem updating your request.'
      render 'edit'
    end
  end

  protected

  def validate_pageable
    fail UnpageableItemError unless @page.pageable?
  end

  def rescue_can_can(*)
    if !current_user.webauth_user? && create_via_post?
      redirect_to login_path(referrer: create_pages_path(page: params[:page].except(:user_attributes)))
    else
      super
    end
  end

  def create_params
    params.require(:page).permit(:destination,
                                 :item_id,
                                 :origin,
                                 :origin_location,
                                 barcodes: [],
                                 data: [:comments],
                                 user_attributes: [:name, :email])
  end

  def update_params
    params.require(:page).permit(:needed_date)
  end

  def local_object_param
    params[:page]
  end

  class UnpageableItemError < StandardError
  end
end
