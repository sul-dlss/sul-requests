# frozen_string_literal: true

###
#  Controller to handle base Create, Read, Update, and Delete actions of request objects.
#  Other request type specific controllers will handle behaviors for their particular types.
###
class RequestsController < ApplicationController
  include RequestStrongParams
  include ModalLayout

  before_action :capture_email_field
  before_action :modify_item_selector_checkboxes, only: :create
  before_action :modify_item_proxy_status, only: :create

  load_and_authorize_resource instance_name: 'request'

  before_action :set_current_request_defaults, :validate_request_type, :redirect_delegatable_requests, only: :new
  before_action :set_current_user_for_request, only: :create, if: :webauth_user?

  helper_method :current_request, :delegated_request?

  def new
  end

  def create
    if current_request.save && current_request.submit!
      send_confirmation
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

  def send_confirmation
    current_request.send_confirmation! if current_request.symphony_response.success?
  end

  def redirect_delegatable_requests
    return if delegated_request? || current_request.scannable?

    redirect_to delegated_new_request_path(current_request)
  end

  def delegated_request?
    self.class < RequestsController
  end

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
    rescue_new_record_via_post || rescue_status_pages || super
  end

  def rescue_new_record_via_post
    return unless !current_user.webauth_user? && create_via_post? && current_request.new_record?

    bounce_request_through_webauth
  end

  def rescue_status_pages
    return unless params[:action].to_sym == :status
    return if current_user.webauth_user?

    redirect_to login_path(referrer: request.original_url)
  end

  def bounce_request_through_webauth
    request_params = params[:request].except(:user_attributes)
    create_path = polymorphic_url([:create, current_request], request_context_params.merge(request: request_params.to_unsafe_h))
    referrer = interstitial_path(redirect_to: create_path)
    redirect_to login_path(referrer: referrer)
  end

  def check_if_proxy_sponsor
    return unless current_request.user.sponsor? && params[:request][:proxy].nil?

    render 'sponsor_request'
  end

  def delegated_new_request_path(request, url_params = nil)
    url_params ||= params.except(:controller, :action).to_unsafe_h
    request.delegate_request!
    new_polymorphic_path(request.type.underscore, url_params)
  end
  helper_method :delegated_new_request_path

  def modify_item_selector_checkboxes
    request_params = params[:request]
    return unless request_params && request_params[:barcodes].is_a?(Hash)

    request_params[:barcodes] = request_params[:barcodes].select { |_, checked| checked == '1' }.keys
  end

  def modify_item_proxy_status
    return unless params[:request]

    params[:request][:proxy] &&= params[:request][:proxy] == 'true'
  end

  def redirect_to_success_with_token
    options = {}
    options[:token] = current_request.encrypted_token unless current_request.user.webauth_user?
    options.merge!(request_context_params)

    redirect_to polymorphic_path([:successful, current_request], options)
  end

  def request_context_params
    { modal: params[:modal] }
  end

  def capture_email_field
    raise HoneyPotFieldError if params[:email].present?
  end

  class HoneyPotFieldError < StandardError
  end
end
