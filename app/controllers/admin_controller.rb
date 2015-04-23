# Controller to handle mediations for admins
class AdminController < ApplicationController
  def index
    @requests = Request.all.group_by(&:origin).sort
    authorize! :index, @requests
  end
end
