# frozen_string_literal: true

# FOLIO requests
class FolioRequestsController < ApplicationController
  include FolioController

  before_action :authenticate_user!

  before_action :load_requests
  before_action :load_request, except: [:index]

  rescue_from RequestException, with: :deny_access

  # Renders user requests from FOLIO
  #
  # GET /requests
  # GET /requests.json
  def index
    render 'async' and return if params[:async]
  end

  # Renders a form for editing a request/hold
  #
  # GET /requests/:id/edit
  def edit
    respond_to do |format|
      format.html do
        return render layout: false if request.xhr?
      end
    end
  end

  # Handles form submission for changing or canceling requests/holds/etc in FOLIO
  #
  # PATCH /requests/:id
  # PUT /requests/:id
  def update # rubocop:disable Metrics/AbcSize
    destroy && return if params['cancel'].present?

    flash[:success] = []
    flash[:error] = []

    handle_change_pickup_service_point if params['service_point'].present?
    handle_change_pickup_expiration if params['not_needed_after'].present? &&
                                       params['not_needed_after'] != params['current_fill_by_date']

    redirect_to folio_requests_path(group: params[:group])
  end

  # Handles form submission for canceling requests/holds/etc in FOLIO
  #
  # DELETE /requests/:id
  def destroy # rubocop:disable Metrics/AbcSize
    @response = FolioClient.new.cancel_request(@request.key, patron_or_group.key)

    if @response.status == 204
      flash[:success] = t 'mylibrary.request.cancel.success_html', title: params['title']
    else
      Rails.logger.error(@response.body)
      flash[:error] = t 'mylibrary.request.cancel.error_html', title: params['title']
    end

    redirect_to folio_requests_path(group: params[:group])
  end

  private

  def load_requests
    @requests = patron_or_group.requests.sort_by { |request| request.sort_key(:date) }
  end

  def load_request
    @request = @requests.find { |r| r.key == params['id'] }
    raise RequestException, 'Error' unless @request
  end

  def handle_change_pickup_service_point(ils_client: FolioClient.new)
    response_flash_message(response: ils_client.change_pickup_service_point(@request.key, service_point_param),
                           translation_key: 'change_pickup_service_point')
  end

  def handle_change_pickup_expiration(ils_client: FolioClient.new)
    response_flash_message(response: ils_client.change_pickup_expiration(@request.key, pickup_expiration_param),
                           translation_key: 'change_pickup_expiration')
  end

  def response_flash_message(response:, translation_key:)
    case response.status
    when 204
      flash[:success].push(t("mylibrary.request.#{translation_key}.success_html", title: params['title']))
    else
      Rails.logger.error(response.body)
      flash[:error].push(t("mylibrary.request.#{translation_key}.success_html", title: params['title']))
    end
  end

  def service_point_param
    params.require(:service_point)
  end

  def pickup_expiration_param
    params.require(:not_needed_after)
  end

  def deny_access
    flash[:error] = 'An unexpected error has occurred'

    redirect_to folio_requests_path(group: params[:group])
  end
end
