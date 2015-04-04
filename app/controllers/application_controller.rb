# nodoc: Autogenerated
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def current_user
    return unless user_id.present?
    @current_user ||= User.find_or_create_by(webauth: user_id)
  end
  helper_method :current_user

  private

  def user_id
    ENV['REMOTE_USER']
  end
end
