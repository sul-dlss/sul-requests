# frozen_string_literal: true

###
#  Controller for managing Aeon user information
###
class AeonUsersController < ApplicationController
  include AeonController

  before_action do
    authorize! :create, Aeon::User
  end

  def new; end

  def accept_terms
    params.require(:aeon_terms)

    aeon_client.create_user(username: current_user.email_address) if ActiveModel::Type::Boolean.new.cast(params[:aeon_terms])

    redirect_back_or_to(params[:referer])
  end
end
