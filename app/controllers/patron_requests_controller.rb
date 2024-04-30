# frozen_string_literal: true

###
#  Controller to handle patron requests (e.g. hold/recall, page, scans, etc)
###
class PatronRequestsController < ApplicationController
  layout 'application_new'
  load_and_authorize_resource instance_name: :request, new: :login
  skip_authorize_resource only: :new
  before_action :assign_new_attributes, only: [:new]
  before_action :authorize_new_request, only: [:new]
  before_action :associate_request_with_patron, only: [:new, :create]
  helper_method :current_request, :new_params

  def show; end

  def new
    render 'unauthorized' unless can? :prepare, current_request
  end

  def create
    redirect_to current_request.finding_aid if current_request.aeon_page? && current_request.finding_aid?

    if @request.save && @request.submit_later
      redirect_to @request
    else
      render 'new'
    end
  end

  protected

  def assign_new_attributes
    current_request.assign_attributes(**new_params)
  end

  # SSO or library-id users don't need to re-login, but name/email users always need to provide their information
  # for each request.
  #
  # Aeon pages never need authentication, because Aeon will handle that as part of its request flow.
  def authorize_new_request # rubocop:disable Metrics/AbcSize
    return if current_user.patron.present?
    return if params[:step].present? && current_user.patron.email.present?
    return if current_request.aeon_page?

    flash.now[:error] = t('sessions.login_by_sunetid.error_html') if sunetid_without_folio_account?

    render 'login'
  end

  def current_request
    @request
  end

  def associate_request_with_patron
    @request.patron = current_user.patron
  end

  def sunetid_without_folio_account?
    current_user.sso_user? && current_user.patron.blank?
  end

  def new_params
    params.require(:instance_hrid)
    params.require(:origin_location_code)

    params.permit(:instance_hrid, :origin_location_code, :barcode)
  end

  def patron_request_params
    params.require(:patron_request).permit(:patron_email, :instance_hrid, :origin_location_code, :needed_date, :service_point_code, :proxy,
                                           :fulfillment_type, :request_type,
                                           :scan_page_range, :scan_authors, :scan_title,
                                           :barcode, barcodes: [])
  end
end
