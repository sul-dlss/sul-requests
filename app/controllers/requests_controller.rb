###
#  Controller to handle base Create, Read, Update, and Delete actions of request objects.
#  Other request type specific controllers will handle behaviors for their particular types.
###
class RequestsController < ApplicationController
  load_and_authorize_resource
  before_filter :validate_new_params, only: :new

  def new
    request_defaults(@request)
    if @request.scannable?
      render
    else
      @request.becomes!(Page)
      redirect_to new_polymorphic_path(@request.type.downcase, params.except(:controller, :action))
    end
  end

  protected

  def validate_new_params
    params.require(:origin)
    params.require(:item_id)
    params.require(:location)
  end

  def request_defaults(request)
    request.origin = params[:origin]
    request.item_id = params[:item_id]
    request.origin_location = params[:location]
  end
end
