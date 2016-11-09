# Controller to handle mediations for admins
class AdminController < ApplicationController
  before_action only: [:approve_item, :holdings] do
    authorize! :manage, (
      @request = MediatedPage.find(params[:id]).tap do |request|
        request.live_lookup = false
      end
    )
  end

  def index
    authorize! :manage, Request.new
    @dashboard = Dashboard.new
    @requests = @dashboard.recent_requests(params[:page], params[:per] || 100)
  end

  def show
    authorize! :manage, Request.new(origin: params[:id]).library_location
    @dates = next_three_days_with_requests
    @mediated_pages = mediated_pages
  end

  def holdings
    render layout: false
  end

  def approve_item
    status = @request.item_status(params[:item])
    status.approve!(current_user.webauth) unless status.approved?

    if @request.symphony_response.success?(params[:item])
      render json: status, layout: false
    else
      render json: status, layout: false, status: 500
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

  def mediated_pages
    if filtered_by_done?
      completed_mediated_pages
    elsif filtered_by_date?
      date_filtered_mediated_pages
    else
      pending_mediated_pages
    end
  end

  def completed_mediated_pages
    MediatedPage.completed.for_origin(params[:id]).page(page).per(per)
  end

  def date_filtered_mediated_pages
    MediatedPage.for_date(params[:date])
  end

  def pending_mediated_pages
    MediatedPage.unapproved.for_origin(params[:id])
  end

  def page
    params[:page]
  end

  def per
    params.fetch(:per_page, 100)
  end

  def next_three_days_with_requests
    MediatedPage.needed_dates_for_origin_after_date(
      origin: params[:id],
      date: Time.zone.today
    ).take(3)
  end

  def rescue_can_can(*)
    return super if webauth_user? || params[:action] == 'approve_item'
    redirect_to login_path(referrer: request.original_url)
  end
end
