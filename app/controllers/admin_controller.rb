# Controller to handle mediations for admins
class AdminController < ApplicationController
  def index
    authorize! :manage, Request.new
    @dashboard = Dashboard.new
  end

  def show
    authorize! :manage, Request.new(origin: params[:id]).library_location
    @mediated_pages = MediatedPage.where(origin: params[:id]).order(:origin).page(page).per(per)
  end

  private

  def page
    params[:page]
  end

  def per
    params.fetch(:per_page, 100)
  end
end
