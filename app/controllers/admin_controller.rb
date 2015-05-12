# Controller to handle mediations for admins
class AdminController < ApplicationController
  def index
    authorize! :manage, Request.new
    @dashboard = Dashboard.new
  end

  def show
    authorize! :manage, Request.new(origin: params[:id]).library_location
    @mediated_pages = MediatedPage.where(origin: params[:id]).order(:origin)
  end
end
