# frozen_string_literal: true

# Controller to handle mediations for admins
class AdminController < ApplicationController
  before_action only: [:approve_item, :holdings, :mark_as_done, :comment] do
    authorize! :admin, (
      @request = PatronRequest.find(params[:id])
    )
  end

  before_action :load_and_authorize_library_location, only: [:show]

  def index
    authorize! :read, :admin
    @requests = dashboard_patron_requests
  end

  def show
    @dates = next_three_days_with_requests
    @mediated_pages = mediated_pages

    authorize! :admin, @mediated_pages.first || PatronRequest.new
  end

  def holdings
    render layout: false
  end

  def approve_item
    @request.approve_item(params[:item], approver: current_user)

    render 'holdings', layout: false
  end

  def mark_as_done
    @request.update(request_type: 'mediated/done')
    render 'holdings', layout: false
  end

  def comment
    @request.admin_comments.create(create_comment_params)
    render 'holdings', layout: false
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
    PatronRequest.for_origin(params[:id]).completed.page(page).per(per_page).order(needed_date: 'desc', created_at: 'desc')
  end

  def date_filtered_mediated_pages
    origin_filtered_mediated_pages.for_date(params[:date])
  end

  def create_date_filtered_mediated_pages
    origin_filtered_mediated_pages.for_create_date(params[:created_at])
  end

  def pending_mediated_pages
    PatronRequest.for_origin(params[:id]).unapproved.order(needed_date: 'asc', created_at: 'desc')
  end

  def origin_filtered_mediated_pages
    PatronRequest.mediated.for_origin(params[:id])
  end

  def page
    params[:page]
  end

  def per_page
    params.fetch(:per_page, 100)
  end

  def next_three_days_with_requests
    PatronRequest.mediated.needed_dates_for_origin_after_date(
      origin: params[:id],
      date: Time.zone.today,
      count: 3
    )
  end

  def rescue_can_can(*)
    return super if sso_user? || params[:action] == 'approve_item'

    redirect_to login_by_sunetid_path(referrer: request.original_url)
  end

  def load_and_authorize_library_location
    @library_location = if Settings.mediateable_origins.dig(params[:id], :library_override)
                          LibraryLocation.new(Settings.mediateable_origins.dig(params[:id], :library_override), params[:id])
                        else
                          LibraryLocation.new(params[:id])
                        end

    authorize! :manage, @library_location
  end

  def create_comment_params
    params.require(:admin_comment).permit(:comment).to_h.merge(commenter: current_user.sunetid)
  end
end
