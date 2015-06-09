###
#  Controller to handle particular behaviors for Scan type requests
###
class ScansController < RequestsController
  def new
    request_defaults(@scan)
    validate_scannable
  end

  def create
    if @scan.update(create_params.merge(user_id: current_user.id))
      @scan.send_confirmation!
      redirect_to illiad_query(@scan)
    else
      flash[:error] = 'There was a problem creating your scan request.'
      render 'new'
    end
  end

  def update
    if @scan.update(update_params)
      flash[:success] = 'Scan request was successfully updated.'
      redirect_to root_url
    else
      flash[:error] = 'There was a problem updating your scan request.'
      render 'edit'
    end
  end

  def current_request
    @scan ||= Scan.new
  end

  protected

  def illiad_query(scan)
    illiad_params = {
      'Action': '10', 'Form': '30', 'rft.genre': 'scananddeliverArticle',
      'rft.jtitle': scan.item_title,
      'rft.au': scan.data[:authors],
      'rft.pages': scan.data[:page_range],
      'rft.atitle': scan.data[:section_title],
      'rft.volume': scan.holdings.first.callnumber,
      'scan_referrer': successful_scan_url(scan)
    }
    Settings.sul_illiad + "#{illiad_params.to_query}"
  end

  def validate_scannable
    fail UnscannableItemError unless @scan.scannable?
  end

  def rescue_can_can(*)
    if !current_user.webauth_user? && create_via_post?
      redirect_to login_path(referrer: create_scans_path(scan: params[:scan].except(:user_attributes)))
    else
      super
    end
  end

  def create_params
    params.require(:scan).permit(:item_id,
                                 :origin,
                                 :origin_location,
                                 :authors,
                                 :page_range,
                                 :section_title,
                                 barcodes: [])
  end

  def local_object_param
    params[:scan]
  end

  def update_params
    params.require(:scan).permit(:needed_date)
  end

  class UnscannableItemError < StandardError
  end
end
