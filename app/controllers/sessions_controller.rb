# frozen_string_literal: true

# :nodoc:
class SessionsController < ApplicationController
  # Handle login for Barcode + PIN users by authenticating them with the
  # ILS using the Warden configuration.
  #
  # GET /sessions/login_by_library_id
  def login_by_library_id
    if request.env['warden'].authenticate(:library_id)
      redirect_after_login
    else
      redirect_to post_auth_redirect_url, flash: { error: t('.alert') }
    end
  end

  # Handle Stanford single-sign-on users; this route should be protected by
  # Shibboleth, so if they get here we'll be able to read the necessary user
  # information out of the request headers (using the Warden configurations)
  #
  # GET /sessions/login_by_sunetid
  def login_by_sunetid
    if request.env['warden'].authenticate(:shibboleth, :development_shibboleth_stub)
      redirect_after_login
    else
      redirect_to post_auth_redirect_url, flash: {
        error: t('.error_html', mailto: Settings.ACCESS_SERVICES_EMAIL)
      }
    end
  end

  # Handle user logout by destroying their current application session and
  # sending them through the single-sign-on logout process (if necessary)
  #
  # GET /logout
  def destroy
    needs_shibboleth_logout = current_user&.shibboleth?
    request.env['warden'].logout

    if needs_shibboleth_logout
      redirect_to '/Shibboleth.sso/Logout'
    else
      redirect_to root_url
    end
  end

  private

  def redirect_after_login
    if params[:referrer]
      redirect_to post_auth_redirect_url
    else
      redirect_back fallback_location: root_url
    end
  end

  def post_auth_redirect_url
    params[:referrer].presence || root_url
  end
end
