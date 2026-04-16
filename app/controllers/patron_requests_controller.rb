# frozen_string_literal: true

###
#  Controller to handle patron requests (e.g. hold/recall, page, scans, etc)
###
class PatronRequestsController < ApplicationController
  include FolioController

  rescue_from EadClient::Error, with: :handle_ead_client_error
  rescue_from EadClient::InvalidDocument, with: :handle_invalid_ead_document

  check_authorization

  bot_challenge only: [:new]

  before_action :redirect_aeon_finding_aid_requests, only: [:new], if: lambda {
    !use_requests_redesign? && (params[:Value].present? || params[:value].present?)
  }

  load_resource
  before_action :assign_new_attributes, only: [:new]
  before_action :aeon_email_present, only: [:new]
  before_action :authorize_new_request, only: [:new]
  authorize_resource

  before_action :associate_request_with_patron, only: [:new, :create]
  before_action :redirect_aeon_pages, only: [:create]
  before_action :require_aeon_terms, only: [:new, :create]
  before_action :redirect_finding_aid_pages, if: lambda {
    use_requests_redesign? && @patron_request.instance_hrid && @patron_request.finding_aid? && params[:ead_url].blank?
  }, only: [:new]

  helper_method :current_request, :new_params

  rescue_from CanCan::AccessDenied do |_exception|
    render 'unauthorized', status: :forbidden
  end

  def show
    if @patron_request.aeon_page? && use_requests_redesign? # rubocop:disable Style/GuardClause
      @aeon_requests = Aeon::RequestGrouping.new(current_user.aeon.requests.select do |x|
        x.reference_number == @patron_request.to_global_id.to_s
      end)
      request.variant = :aeon
    end
  end

  def new
    request.variant = :aeon if @patron_request.aeon_page?
    request.variant = :aeonredesign if (@patron_request.ead_url || @patron_request.aeon_page?) && use_requests_redesign?
  end

  def create
    if @patron_request.save && @patron_request.submit_later
      redirect_to @patron_request
    else
      render 'new'
    end
  end

  def require_aeon_terms
    return unless use_requests_redesign? && @patron_request.aeon_page?
    return if current_user.aeon.persisted?

    redirect_to new_aeon_user_path(referrer: request.original_url) and return if current_user.name_email_user?

    render 'aeon_terms'
  end

  protected

  def current_request
    @patron_request
  end

  def assign_new_attributes
    @patron_request.assign_attributes(**new_params)
  end

  def aeon_email_present
    return unless @patron_request.aeon_page? && current_user.library_id?

    render 'no_email' if current_user.email_address.blank? && use_requests_redesign?
  end

  # SSO or library-id users don't need to re-login, but name/email users always need to provide their information
  # for each request.
  #
  # Aeon pages never need authentication, because Aeon will handle that as part of its request flow.
  def authorize_new_request # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return if @patron_request.aeon_page? && (current_user.email_address.present? || !use_requests_redesign?)

    return if current_user.patron.present? || (params[:step].present? && current_user.patron.email.present?)

    flash.now[:error] = t('sessions.login_by_sunetid.error_html') if sunetid_without_folio_account? && !@patron_request.aeon_page?

    render 'login'
  end

  def redirect_aeon_finding_aid_requests
    ead_url = params[:Value].presence || params[:value].presence || params[:ead_url].presence

    return if ead_url.blank?

    redirect_to Settings.aeon_archives_url + "&Value=#{ead_url}", allow_other_host: true
  end

  def redirect_aeon_pages
    return if use_requests_redesign?

    return unless @patron_request.aeon_page? && @patron_request.finding_aid?

    redirect_to @patron_request.finding_aid
  end

  def redirect_finding_aid_pages
    return unless @patron_request.finding_aid?

    ead_url = FindingAidLookupService.new(@patron_request.finding_aid).ead_url

    if ead_url.present?
      redirect_to new_archives_request_path(**new_params, ead_url: ead_url)
    else
      redirect_to @patron_request.finding_aid, allow_other_host: true
    end
  end

  def associate_request_with_patron
    @patron_request.patron = current_user.patron
    @patron_request.user = current_user if current_user.persisted?
  end

  def sunetid_without_folio_account?
    current_user.sso_user? && current_user.patron.blank?
  end

  def new_params # rubocop:disable Metrics/AbcSize
    if params[:ead_url] || params[:value] || params[:Value]
      ead_url = params[:ead_url] || params[:value] || params[:Value]
    else
      params.require(:instance_hrid)
      params.require(:origin_location_code)
    end

    params.permit(:instance_hrid, :origin_location_code).to_h.merge(requested_barcodes: Array(params[:barcode]),
                                                                    ead_url: ead_url)
  end

  def patron_request_params
    aeon_term_params = params.dig(:patron_request, :aeon_item)&.keys&.index_with do
      [:id, :title, :appointment_id, :for_publication, :requested_pages, :additional_information, { hierarchy: [] }]
    end

    params.expect(patron_request: [:patron_email, :instance_hrid, :origin_location_code, :needed_date, :service_point_code, :proxy,
                                   :for_sponsor_id, :for_sponsor,
                                   :fulfillment_type, :request_type,
                                   :scan_page_range, :scan_authors, :scan_title,
                                   :aeon_reading_special, :aeon_terms, :ead_url,
                                   { barcodes: [] }, { aeon_item: aeon_term_params }])
  end

  def handle_ead_client_error
    render 'ead_error'
  end

  def handle_invalid_ead_document
    render 'ead_invalid'
  end
end
