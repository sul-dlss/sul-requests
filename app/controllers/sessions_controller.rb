# frozen_string_literal: true

# :nodoc:
class SessionsController < ApplicationController
  before_action :logout_user, only: [:login_by_university_id, :login_by_sunetid, :register_visitor]
  before_action :verify_recaptcha_challenge, only: :register_visitor

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
    if Settings.features.authenticate_name_email_users && params[:code].blank?
      send_otp_challenge
    elsif request.env['warden'].authenticate(:register_visitor)
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

  def proxy
    session[:proxyFor] = params[:id].presence

    redirect_back_or_to(params[:referrer])
  end

  private

  def send_otp_challenge
    unless params[:patron_email].to_s.match?(URI::MailTo::EMAIL_REGEXP)
      return redirect_to post_action_redirect_url, flash: { error: t('.alert') }
    end

    SendOtpJob.perform_later(params[:patron_email])

    render 'sessions/register_visitor'
  end

  def verify_recaptcha_challenge
    return unless recaptcha_required?
    return if verify_recaptcha

    redirect_to post_action_redirect_url, flash: { error: t('.recaptcha_alert') }
  end

  def recaptcha_required?
    return false unless Rails.env.production?
    return true unless Settings.features.authenticate_name_email_users

    params[:code].blank?
  end

  def needs_shibboleth_logout?
    return false if Rails.env.development?

    request.env['warden']&.user&.shibboleth?
  end

  def logout_user
    return if Rails.env.test?

    request.env['warden'].logout
  end
end
