###
#  Controller to handle particular behaviors for Page type requests
###
class PagesController < RequestsController
  def new
    request_defaults(@page)
  end

  def create
    if @page.update(create_params)
      flash[:success] = 'Request was successfully created.'
      redirect_to root_url
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

  def create_params
    params.require(:page).permit(:destination,
                                 :item_id,
                                 :needed_date,
                                 :origin,
                                 :origin_location)
  end

  def update_params
    params.require(:page).permit(:needed_date)
  end
end
