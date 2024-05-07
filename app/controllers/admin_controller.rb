# frozen_string_literal: true

# Controller to handle mediations for admins
class AdminController < ApplicationController
  before_action only: [:approve_item, :holdings] do
    authorize! :manage, (
      @request = MediatedPage.find(params[:id])
    )
  end

  before_action :load_and_authorize_library_location, only: [:show]

  def index
    authorize! :admin, PatronRequest.new
    @requests = dashboard_patron_requests
  end

  def old_requests_index
    authorize! :manage, Request.new
    @dashboard = Dashboard.new
    @requests = dashboard_requests
  end

  def show
    @dates = next_three_days_with_requests
    @mediated_pages = mediated_pages
  end

  def holdings
    render layout: false
  end

  def approve_item
    status = @request.item_status(params[:item])
    status.approve!(current_user.sunetid) unless status.approved?

    if @request.ils_response.success?(params[:item])
      render json: status, layout: false
    else
      render json: status, layout: false, status: :internal_server_error
    end
  end

  private

  def filtered_by_done?
    params[:done] == 'true'
  end
  helper_method :filtered_by_done?

  def filtered_by_date?
    params[:date].present?
  end
  helper_method :filtered_by_date?

  def filtered_by_create_date?
    params[:created_at].present?
  end
  helper_method :filtered_by_create_date?

  def filter_metric
    params[:metric].to_sym if params[:metric].present?
  end
  helper_method :filter_metric

  def filter_type
    params[:metric].classify if params[:metric].present?
  end

  def dashboard_requests
    if filtered_by_create_date?
      dashboard_create_date_filtered_requests
    else
      dashboard_recent_requests
    end
  end

  def dashboard_patron_requests
    if filtered_by_create_date?
      PatronRequest.for_create_date(params[:created_at])
    else
      PatronRequest.recent.page(page).per(per_page)
    end
  end

  def dashboard_create_date_filtered_requests
    Request.for_create_date(params[:created_at]).for_type(filter_type)
  end

  def dashboard_recent_requests
    @dashboard.recent_requests(page, per_page).for_type(filter_type)
  end

  def mediated_pages
    if filtered_by_done?
      completed_mediated_pages
    elsif filtered_by_date?
      date_filtered_mediated_pages
    elsif filtered_by_create_date?
      create_date_filtered_mediated_pages
    else
      pending_mediated_pages
    end
  end

  def completed_mediated_pages
    origin_filtered_mediated_pages.completed.page(page).per(per_page).order(needed_date: 'desc', created_at: 'desc')
  end

  def date_filtered_mediated_pages
    origin_filtered_mediated_pages.for_date(params[:date])
  end

  def create_date_filtered_mediated_pages
    origin_filtered_mediated_pages.for_create_date(params[:created_at])
  end

  def pending_mediated_pages
    origin_filtered_mediated_pages.unapproved.order(needed_date: 'asc', created_at: 'desc')
  end

  def origin_filtered_mediated_pages
    MediatedPage.for_origin(params[:id])
  end

  def page
    params[:page]
  end

  def per_page
    params.fetch(:per_page, 100)
  end

  def next_three_days_with_requests
    MediatedPage.needed_dates_for_origin_after_date(
      origin: params[:id],
      date: Time.zone.today
    ).take(3)
  end

  def rescue_can_can(*)
    return super if sso_user? || params[:action] == 'approve_item'

    redirect_to login_by_sunetid_path(referrer: request.original_url)
  end

  def range_param(default: Time.zone.now.beginning_of_day...Time.zone.now)
    from = (params[:from] && Time.zone.parse(params[:from])) || default.first
    to = (params[:to] && Time.zone.parse(params[:to])) || default.last

    from...to
  end

  def request_has_items_approved_within_range?(request, range)
    request.item_statuses.select do |item_status|
      item_status.approved? &&
        item_status.approval_time &&
        range.cover?(Time.zone.parse(item_status.approval_time))
    end
  end

  def load_and_authorize_library_location
    @library_location = if Settings.mediateable_origins.dig(params[:id], :library_override)
                          LibraryLocation.new(Settings.mediateable_origins.dig(params[:id], :library_override), params[:id])
                        else
                          LibraryLocation.new(params[:id])
                        end

    authorize! :manage, @library_location
  end
end
