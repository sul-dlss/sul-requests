###
#  Controller to handle base Create, Read, Update, and Delete actions of request objects.
#  Other request type specific controllers will handle behaviors for their particular types.
###
class RequestsController < ApplicationController
  before_action :modify_item_selector_checkboxes, only: :create
  load_and_authorize_resource
  before_action :validate_new_params, only: :new

  def new
    request_defaults(@request)
    if @request.scannable?
      render
    else
      redirect_to delegated_new_request_path(@request)
    end
  end

  def current_request
    @request
  end
  helper_method :current_request

  protected

  def create_params
    params.require(:request).permit(:destination,
                                    :item_id,
                                    :origin, :origin_location,
                                    :needed_date,
                                    :item_comment, :request_comment,
                                    :authors, :page_range, :section_title, # scans
                                    barcodes: [],
                                    user_attributes: [:name, :email, :library_id])
  end

  def update_params
    params.require(:request).permit(:needed_date)
  end

  def local_object_param
    params[:request]
  end

  def delegated_new_request_path(request)
    request.delegate_request!
    new_polymorphic_path(request.type.underscore, params.except(:controller, :action))
  end
  helper_method :delegated_new_request_path

  def validate_new_params
    params.require(:origin)
    params.require(:item_id)
    params.require(:origin_location)
  end

  def request_defaults(request)
    request.origin = params[:origin]
    request.item_id = params[:item_id]
    request.origin_location = params[:origin_location]
    request.requested_barcode = params[:barcode] if params[:barcode]
  end

  def create_via_post?
    params[:action].to_sym == :create && request.post?
  end

  def create_params_with_current_user
    p = create_params
    return p if p[:user_attributes] &&
                p[:user_attributes][:name] &&
                p[:user_attributes][:email]
    p[:user_id] = current_user.id if current_user.webauth_user?
    p
  end

  def modify_item_selector_checkboxes
    return unless local_object_param
    return unless local_object_param[:barcodes]
    return unless local_object_param[:barcodes].is_a?(Hash)
    local_object_param[:barcodes] = local_object_param[:barcodes].map do |barcode, checked|
      barcode if checked == '1'
    end.compact
  end

  def redirect_to_success_with_token(request)
    if current_user.webauth_user?
      redirect_to polymorphic_path([:successful, request])
    else
      redirect_to polymorphic_path([:successful, request], token: request.encrypted_token)
    end
  end
end
