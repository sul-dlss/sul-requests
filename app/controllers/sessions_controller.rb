# frozen_string_literal: true

# :nodoc:
class SessionsController < ApplicationController
  before_action :set_home_page_flash_message, only: :index

  # Render the application home page with various login options
  #
  # GET /
  def index
    @ils_ok = ils_client.ping

    redirect_to summaries_url if current_user?
  end

  # Render a login form for Barcode + PIN users (Stanford single-sign-on are
  # authenticated using a different route)
  #
  # GET /login
  def form; end

  # Handle login for Barcode + PIN users by authenticating them with the
  # ILS using the Warden configuration.
  #
  # GET /sessions/login_by_library_id
  def login_by_library_id
    if request.env['warden'].authenticate(:library_id)
      redirect_to summaries_url
    else
      redirect_to login_url, alert: t('mylibrary.sessions.login_by_library_id.alert')
    end
  end

  # Handle Stanford single-sign-on users; this route should be protected by
  # Shibboleth, so if they get here we'll be able to read the necessary user
  # information out of the request headers (using the Warden configurations)
  #
  # GET /sessions/login_by_sunetid
  def login_by_sunetid
    if request.env['warden'].authenticate(:shibboleth, :development_shibboleth_stub)
      redirect_to summaries_url
    else
      redirect_to root_url, flash: {
        error: t('mylibrary.sessions.login_by_sunetid.error_html', mailto: Settings.ACCESS_SERVICES_EMAIL)
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

  def set_home_page_flash_message
    return unless Settings.home_page_flash_message_html

    # rubocop:disable Rails/OutputSafety
    flash[:success] = Settings.home_page_flash_message_html.html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
