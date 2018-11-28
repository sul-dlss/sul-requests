# frozen_string_literal: true

###
#  Controller for handling login/logout and redirecting with flash messages.
###
class AuthenticationController < ApplicationController
  def login
    flash[:success] = 'You have been successfully logged in.'

    if params[:referrer]
      redirect_to params[:referrer]
    else
      redirect_back fallback_location: root_url
    end
  end

  def logout
    flash[:notice] = 'You have been successfully logged out.'
    redirect_to '/Shibboleth.sso/Logout'
  end
end
