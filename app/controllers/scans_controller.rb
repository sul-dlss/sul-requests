# frozen_string_literal: true

###
#  Controller to handle particular behaviors for Scan type requests
###
class ScansController < RequestsController
  before_action only: :create do
    check_illiad unless params[:illiad_success]
  end

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
      barcodes: params[:request][:barcodes].to_unsafe_h # Pulling barcodes from params so they are not transformed
    }.merge(request_context_params)
  end

  def illiad_request
    IlliadRequest.new(current_user, current_request).response
  end

  def check_illiad
    response = illiad_request.body
    Rails.logger.info "ILLiad response: #{response}"
    # If there is a connection or url problem the request will be blank.
    # If there is a problem with a POST value (e.g. blank Username) the response will include the word 'invalid'
    redirect_to sorry_unable_path if response.blank? || response.include?('The request is invalid.')
  end

  def validate_request_type
    raise UnscannableItemError unless current_request.scannable?
  end

  class UnscannableItemError < StandardError
  end
end
