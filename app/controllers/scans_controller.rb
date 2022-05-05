# frozen_string_literal: true

###
#  Controller to handle particular behaviors for Scan type requests
###
class ScansController < RequestsController
  protected

  def rescue_new_record_via_post
    if current_user&.webauth_user?
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
      barcodes: params[:request][:barcodes].to_unsafe_h # Pulling barcodes from params so they are not transformed
    }.merge(request_context_params)
  end

  def validate_request_type
    raise UnscannableItemError unless current_request.scannable?
  end

  class UnscannableItemError < StandardError
  end
end
