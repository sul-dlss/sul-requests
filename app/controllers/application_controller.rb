# frozen_string_literal: true

# nodoc: Autogenerated
class ApplicationController < ActionController::Base
  layout 'application_new'
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action -> { flash.now[:error] &&= flash[:error].html_safe if flash[:html_safe] }

  def current_user
    @current_user ||= request.env['warden']&.user&.user_object || User.new
  end

  def current_user?
    current_user.sunetid.present?
  end

  helper_method :current_user, :current_user?, :sso_user?

  private

  def sso_user?
    current_user.sso_user?
  end

  def redirect_after_action
    if params[:referrer]
      redirect_to post_action_redirect_url
    else
      redirect_back fallback_location: root_url
    end
  end

  def post_action_redirect_url
    params[:referrer].presence || root_url
  end
end
