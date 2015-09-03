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
    @mediated_pages = mediated_pages
  end

  def holdings
    render layout: false
  end

  def approve_item
    status = @request.item_status(params[:item])
    status.approve!(current_user.webauth) unless status.approved?
    render json: status, layout: false
  end

  private

  def mediated_pages
    pages = if params[:expired]
              archived_mediated_pages
            else
              active_mediated_pages
            end
    pages.for_origin(params[:id]).page(page).per(per)
  end

  def archived_mediated_pages
    MediatedPage.archived
  end

  def active_mediated_pages
    MediatedPage.active
  end

  def page
    params[:page]
  end

  def per
    params.fetch(:per_page, 100)
  end
end
