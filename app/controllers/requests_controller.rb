# frozen_string_literal: true

###
#  Controller to handle base Create, Read, Update, and Delete actions of request objects.
#  Other request type specific controllers will handle behaviors for their particular types.
###
class RequestsController < ApplicationController
  load_and_authorize_resource instance_name: :request

  helper_method :current_request

  class_attribute :bib_model_class, default: Settings.ils.bib_model.constantize

  rescue_from bib_model_class::NotFound, with: :item_not_found

  def new
    mapped_params = { 'instance_hrid' => new_params[:item_id],
                      'origin_location_code' => params[:origin_location],
                      'barcode' => new_params[:barcode] }
    redirect_to(new_patron_request_path(mapped_params))
  end

  def status; end

  protected

  def new_params
    params.require(:origin)
    params.require(:item_id)
    params.require(:origin_location)

    params.permit(:origin, :item_id, :origin_location, :barcode)
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, params[:token])
  end

  def current_request
    @request
  end

  def rescue_can_can(exception)
    return rescue_status_pages || super if params[:action].to_sym == :status

    super
  end

  def rescue_status_pages
    redirect_to login_by_sunetid_path(referrer: request.original_url) unless current_user.sso_user?
  end

  # Re-raise as ActiveRecord::RecordNotFound so we get a 404 in production
  def item_not_found(exception)
    raise ActiveRecord::RecordNotFound, exception
  end
end
