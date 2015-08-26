###
#  Controller to handle particular behaviors for Scan type requests
###
class ScansController < RequestsController
  protected

  def rescue_can_can(exception)
    if action_name == 'create' && current_user && current_user.webauth_user? && !can?(:create, Scan)
      # if they are logged in, but not eligible, send the user to the appropriate page for
      redirect_to delegated_new_request_path(@request, new_request_params), flash: {
        html_safe: true,
        error: render_to_string(partial: 'ineligible_exception')
      }
    else
      super
    end
  end

  def new_request_params
    {
      origin: @request.origin,
      origin_location: @request.origin_location,
      item_id: @request.item_id,
      barcodes: @request.barcodes
    }.merge(request_context_params)
  end

  def redirect_to_success_with_token
    redirect_to illiad_url
  end

  def illiad_url
    redirect_url = successful_scan_url(current_request, request_context_params)

    IlliadOpenurl.new(current_user, current_request, redirect_url).to_url
  end

  def validate_request_type
    fail UnscannableItemError unless current_request.scannable?
  end

  class UnscannableItemError < StandardError
  end
end
