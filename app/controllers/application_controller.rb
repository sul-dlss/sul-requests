# frozen_string_literal: true

# nodoc: Autogenerated
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from CanCan::AccessDenied, with: :rescue_can_can

  before_action -> { flash.now[:error] &&= flash[:error].html_safe if flash[:html_safe] }

  def current_user
    @current_user ||= CurrentUser.for(request)
  end
  helper_method :current_user

  private

  def sso_user?
    current_user.sso_user?
  end

  def rescue_can_can(exception)
    Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"
    raise exception
  end
end
