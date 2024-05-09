# frozen_string_literal: true

###
#  Enables one to update the needed date property on a MediatedPage request.
###
class NeededDatesController < ApplicationController
  load_and_authorize_resource :patron_request

  def show; end
  def edit; end

  def update
    @patron_request.update(needed_date_params)
    render 'show'
  end

  protected

  def needed_date_params
    params.require(:patron_request).permit(:needed_date)
  end
end
