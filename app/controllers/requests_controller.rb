# frozen_string_literal: true

###
#  Controller to handle base Create, Read, Update, and Delete actions of request objects.
#  Other request type specific controllers will handle behaviors for their particular types.
###
class RequestsController < ApplicationController
  include RequestStrongParams
  include ModalLayout

  before_action :capture_email_field
  before_action :modify_item_selector_checkboxes_or_radios, only: :create
  before_action :modify_item_proxy_status, only: :create

  load_and_authorize_resource instance_name: :request

  before_action :set_current_request_defaults, :validate_request_type, :redirect_delegatable_requests, only: :new
  before_action :set_current_user_for_request, only: :create, if: :sso_user?

  helper_method :current_request, :delegated_request?

  def new
  end

  def create
    if current_request.save && current_request.submit!
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

  def success
  end

  protected

  def current_ability
    @current_ability ||= Ability.new(request_specific_user || current_user, params[:token])
  end

  def request_specific_user
    user_attributes = params.dig(:request, :user_attributes)&.permit(:name, :email, :library_id).to_h.reject { |_k, v| v.blank? }

    User.new(**user_attributes, ip_address: request.remote_ip) if user_attributes.present?
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
    current_request.user = current_user if current_user.sso_user? && !request_specific_user
  end

  def set_current_request_defaults
    current_request.assign_attributes(new_params)
  end

  def validate_request_type
  end

  def rescue_can_can(exception)
    if create_via_post?
      rescue_new_record_via_post
    elsif params[:action].to_sym == :status
      rescue_status_pages
    end || super
  end

  def create_via_post?
    params[:action].to_sym == :create && request.post?
  end

  # if the patron is trying to submit a request and didn't provide a library id or name/email,
  # authenticate them. Since we only provide the library id or name/email option for requests where
  # it will succeed, we should only end up here if the request requires authentication.
  #
  # if we ever validate patron data from the ILS, we'll need to add more logic here
  def rescue_new_record_via_post
    bounce_request_through_sso unless current_user.sso_user?
  end

  def rescue_status_pages
    redirect_to login_path(referrer: request.original_url) unless current_user.sso_user?
  end

  def bounce_request_through_sso
    request_params = request_params_without_user_attrs_or_unselected_barcodes
    create_path = polymorphic_url(
      [:create, current_request], request_context_params.merge(request: request_params.to_unsafe_h)
    )

    referrer = interstitial_path(redirect_to: create_path)
    redirect_to login_path(referrer:)
  end

  # Strips out undesired parameters when sending the user through our auth service
  # Removes user attributes as the user will be returned authenticated
  # Removes unselected barcodes to prevent the auth service from throwing an error with large records
  def request_params_without_user_attrs_or_unselected_barcodes
    return params[:request].except(:user_attributes) unless params.dig(:request, :barcodes)

    params[:request].except(:user_attributes).merge(
      barcodes: barcode_array_or_selected_hash
    )
  end

  # Return the barcodes param if it is an array, otherwise return
  # only the selected barcodes (indicated by a value of "1")
  # Barcodes sent in as an array are assumed as selected, and will be handled downstream
  def barcode_array_or_selected_hash
    barcodes = params.dig(:request, :barcodes)
    return barcodes if barcodes.is_a?(Array)
    return [] if barcodes.keys == ['NO_BARCODE']

    barcodes.select { |_, v| v.to_s == '1' }
  end

  # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  def check_if_proxy_sponsor
    return unless current_request.user&.sso_user? && params[:request][:proxy].nil?

    return unless current_request.user&.sponsor? || (Settings.ils.patron_model == 'Folio::Patron' && current_request.user&.proxy?)

    render 'proxy_request'
  end
  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

  def delegated_new_request_path(request, url_params = nil)
    url_params ||= params.except(:controller, :action).to_unsafe_h
    request.delegate_request!
    new_polymorphic_path(request.type.underscore, url_params)
  end
  helper_method :delegated_new_request_path

  # Overwrite the barcodes attribute in create_params to be checkbox/radio button agnostic.
  # We need the param to be an array since we serialize barcodes in the database as an array.
  def modify_item_selector_checkboxes_or_radios
    return unless create_params && params[:request][:barcodes].present?

    create_params[:barcodes] = item_selector_checkboxes_or_radios_as_array
  end

  # Radio buttons will be represented as an array, and can simply be passed through.
  # Otherwise, the barcodes should be a hash, and we want to only return the ones w/ a value of "1" (selected)
  def item_selector_checkboxes_or_radios_as_array
    barcodes = params[:request][:barcodes]
    return barcodes if barcodes.is_a?(Array)
    return [] if barcodes.keys == ['NO_BARCODE']

    barcodes.select { |_, checked| checked == '1' }.keys
  end

  def modify_item_proxy_status
    return unless create_params

    create_params[:proxy] &&= create_params[:proxy] == 'true'
  end

  def redirect_to_success_with_token
    options = {}
    options[:token] = current_request.encrypted_token unless current_request.user.sso_user?
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
