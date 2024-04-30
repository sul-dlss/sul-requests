# frozen_string_literal: true

###
#  Controller to handle patron requests (e.g. hold/recall, page, scans, etc)
###
class PatronRequestsController < ApplicationController
  layout 'application_new'
  load_and_authorize_resource instance_name: :request, new: :login
  before_action :associate_request_with_patron, only: [:new, :create, :login]
  helper_method :current_request, :new_params

  def show
    PatronRequestMailer.confirmation_email(@request).deliver_later
  end

  def login
    current_request.assign_attributes(**new_params)
  end

  def new
    current_request.assign_attributes(**new_params)
    render 'unauthorized' unless can? :prepare, current_request
    return unless sunetid_without_folio_account?

    flash.now[:error] = t('sessions.login_by_sunetid.error_html')
    render 'login'
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

  def current_request
    @request
  end

  def associate_request_with_patron
    @request.patron = current_user.patron
  end

  def sunetid_without_folio_account?
    current_user.sso_user? && current_user.patron.is_a?(Folio::NullPatron)
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
