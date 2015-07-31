# Controller to handle mediations for admins
class AdminController < ApplicationController
  before_action only: [:approve_item, :holdings] do
    authorize! :manage, (@request = MediatedPage.find(params[:id]))
  end

  def index
    authorize! :manage, Request.new
    @dashboard = Dashboard.new
  end

  def show
    authorize! :manage, Request.new(origin: params[:id]).library_location
    @mediated_pages = MediatedPage.where(origin: params[:id]).order(:origin).page(page).per(per)
  end

  def holdings
    render layout: false
  end

  def approve_item
    status = SearchworksItem::RequestedHoldings::RequestStatus.new(@request, params[:item])
    status.approve!(current_user.webauth) unless status.approved?
    render json: status, layout: false
  end

  private

  def page
    params[:page]
  end

  def per
    params.fetch(:per_page, 100)
  end
end
