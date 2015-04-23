# Controller to handle mediations for admins
class AdminController < ApplicationController
  before_filter do
    authorize! :manage, Request.new
  end

  def index
    @requests = Request.order(:origin).group_by(&:origin)
  end
end
