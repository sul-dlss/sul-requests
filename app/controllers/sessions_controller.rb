# frozen_string_literal: true

# :nodoc:
class SessionsController < ApplicationController
  before_action :logout_user, only: [:login_by_university_id, :login_by_sunetid, :register_visitor]

  # Handle login for University ID + PIN users by authenticating them with the
  # ILS using the Warden configuration.
  #
  # GET /sessions/login_by_university_id
  def login_by_university_id
    if request.env['warden'].authenticate(:university_id)
      redirect_after_action
    else
      redirect_to post_action_redirect_url, flash: { error: t('.alert_html') }
    end
  end

  # Handle Stanford single-sign-on users; this route should be protected by
  # Shibboleth, so if they get here we'll be able to read the necessary user
  # information out of the request headers (using the Warden configurations)
  #
  # GET /sessions/login_by_sunetid
  def login_by_sunetid
    if request.env['warden'].authenticate(:shibboleth, :development_shibboleth_stub)
      redirect_after_action
    else
      redirect_to post_action_redirect_url, flash: { error: t('.alert') }
    end
  end

  # Handle visitor name and email registration
  #
  # GET /sessions/register_visitor
  def register_visitor
    if (!Rails.env.production? || verify_recaptcha) && request.env['warden'].authenticate(:register_visitor)
      redirect_after_action
    else
      redirect_to post_action_redirect_url, flash: { error: t('.alert') }
    end
  end

  # Handle user logout by destroying their current application session and
  # sending them through the single-sign-on logout process (if necessary)
  #
  # GET /logout
  def destroy
    redirect_path = needs_shibboleth_logout? ? '/Shibboleth.sso/Logout' : post_action_redirect_url

    request.env['warden'].logout
    flash[:notice] = t('.notice')

    redirect_to redirect_path
  end

  private

  def needs_shibboleth_logout?
    return false if Rails.env.development?

    request.env['warden']&.user&.shibboleth?
  end

  def logout_user
    return if Rails.env.test?

    request.env['warden'].logout
  end
end
