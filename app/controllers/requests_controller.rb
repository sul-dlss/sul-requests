###
#  Controller to handle base Create, Read, Update, and Delete actions of request objects.
#  Other request type specific controllers will handle behaviors for their particular types.
###
class RequestsController < ApplicationController
  before_action :modify_item_selector_checkboxes, only: :create
  load_and_authorize_resource
  before_action :set_current_request_defaults, only: :new
  before_action :validate_request_type, only: :new
  before_action :redirect_delegatable_requests, only: :new
  before_action :set_current_user_for_request, only: :create, if: :webauth_user?

  helper_method :current_request

  def redirect_delegatable_requests
    return if self.class < RequestsController
    return if current_request.scannable?

    redirect_to delegated_new_request_path(current_request)
  end

  def new
  end

  def create
    if current_request.save
      current_request.send_confirmation!
      redirect_to_success_with_token
    else
      flash[:error] = 'There was a problem creating your request.'
      render 'new'
    end
  end

  def update
    if current_request.update(update_params)
      flash[:success] = 'Request was successfully updated.'
      redirect_to root_url
    else
      flash[:error] = 'There was a problem updating your request.'
      render 'edit'
    end
  end

  protected

  def current_request
    @request
  end

  def set_current_user_for_request
    return if current_request.user && (current_request.user.library_id_user? || current_request.user.non_webauth_user?)

    current_request.user = current_user if current_user.webauth_user?
  end

  def set_current_request_defaults
    current_request.assign_attributes(new_params)
  end

  def validate_request_type
  end

  def rescue_can_can(exception)
    if !current_user.webauth_user? && create_via_post? && current_request.new_record?
      redirect_to login_path(
        referrer: polymorphic_path([:create, current_request],
                                   request: local_object_param.except(:user_attributes))
      )
    else
      super
    end
  end

  def new_params
    validate_new_params

    params.permit(:origin, :item_id, :origin_location, :barcode)
  end

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

  def modify_item_selector_checkboxes
    return unless local_object_param
    return unless local_object_param[:barcodes]
    return unless local_object_param[:barcodes].is_a?(Hash)
    local_object_param[:barcodes] = local_object_param[:barcodes].map do |barcode, checked|
      barcode if checked == '1'
    end.compact
  end

  def redirect_to_success_with_token
    if current_user.webauth_user?
      redirect_to polymorphic_path([:successful, current_request])
    else
      redirect_to polymorphic_path([:successful, current_request], token: current_request.encrypted_token)
    end
  end
end
