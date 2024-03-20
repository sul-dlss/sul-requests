# frozen_string_literal: true

###
#  Controller to handle patron requests (e.g. hold/recall, page, scans, etc)
###
class PatronRequestsController < ApplicationController
  layout 'application_new'
  load_and_authorize_resource

  def show; end

  def new; end

  def create; end

  protected

  def patron_request_params
    params.require(:patron_request).permit(:patron_email, :instance_hrid, :needed_date, :service_point_code)
  end
end
