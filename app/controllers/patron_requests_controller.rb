# frozen_string_literal: true

###
#  Controller to handle patron requests (e.g. hold/recall, page, scans, etc)
###
class PatronRequestsController < ApplicationController
  check_authorization

  load_resource
  before_action :assign_new_attributes, only: [:new]
  before_action :authorize_new_request, only: [:new]
  authorize_resource

  before_action :associate_request_with_patron, only: [:new, :create]
  before_action :redirect_aeon_pages, only: [:create]
  helper_method :current_request, :new_params

  rescue_from CanCan::AccessDenied do |_exception|
    render 'unauthorized', status: :forbidden
  end

  def show; end

  def new; end

  def create
    if @patron_request.save && @patron_request.submit_later
      redirect_to @patron_request
    else
      render 'new'
    end
  end

  protected

  def current_request
    @patron_request
  end

  def assign_new_attributes
    @patron_request.assign_attributes(**new_params)
  end

  # SSO or library-id users don't need to re-login, but name/email users always need to provide their information
  # for each request.
  #
  # Aeon pages never need authentication, because Aeon will handle that as part of its request flow.
  def authorize_new_request # rubocop:disable Metrics/AbcSize
    return if current_user.patron.present? || (params[:step].present? && current_user.patron.email.present?) || @patron_request.aeon_page?

    flash.now[:error] = t('sessions.login_by_sunetid.error_html') if sunetid_without_folio_account?

    render 'login'
  end

  def redirect_aeon_pages
    return unless @patron_request.aeon_page? && @patron_request.finding_aid?

    redirect_to @patron_request.finding_aid
  end

  def associate_request_with_patron
    @patron_request.patron = current_user.patron
  end

  def sunetid_without_folio_account?
    current_user.sso_user? && current_user.patron.blank?
  end

  def new_params
    params.require(:instance_hrid)
    params.require(:origin_location_code)

    params.permit(:instance_hrid, :origin_location_code).to_h.merge(requested_barcodes: Array(params[:barcode]))
  end

  def patron_request_params
    params.require(:patron_request).permit(:patron_email, :instance_hrid, :origin_location_code, :needed_date, :service_point_code, :proxy,
                                           :for_sponsor_name, :for_sponsor,
                                           :fulfillment_type, :request_type,
                                           :scan_page_range, :scan_authors, :scan_title,
                                           :barcode, barcodes: [])
  end
end
