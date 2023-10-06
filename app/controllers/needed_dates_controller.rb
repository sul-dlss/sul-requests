# frozen_string_literal: true

###
#  Enables one to update the needed date property on a MediatedPage request.
###
class NeededDatesController < ApplicationController
  load_and_authorize_resource :mediated_page

  def show; end
  def edit; end

  def update
    @mediated_page.update(mediated_page_params)
    render 'show'
  end

  protected

  def mediated_page_params
    params.require(:mediated_page).permit(:needed_date)
  end
end
