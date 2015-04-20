###
#  Controller to handle particular behaviors for Page type requests
###
class PagesController < RequestsController
  def new
    request_defaults(@page)
  end

  def create
    if @page.update(create_params_with_current_user)
      flash[:success] = 'Request was successfully created.'
      redirect_to root_path
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

  def rescue_can_can(*)
    if params[:action].to_sym == :create && !current_user.webauth_user?
      redirect_to login_path(referrer: new_page_path(params[:page].except(:user_attributes)))
    else
      super
    end
  end

  def create_params_with_current_user
    p = create_params
    return p if p[:user_attributes] &&
                p[:user_attributes][:name] &&
                p[:user_attributes][:email]
    p[:user_id] = current_user.id if current_user.webauth_user?
    p
  end

  def create_params
    params.require(:page).permit(:destination,
                                 :item_id,
                                 :needed_date,
                                 :origin,
                                 :origin_location,
                                 user_attributes: [:name, :email])
  end

  def update_params
    params.require(:page).permit(:needed_date)
  end
end
