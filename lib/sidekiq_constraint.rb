# frozen_string_literal: true

# determine if current user is allowed to see sidekiq pages
class SidekiqConstraint
  def matches?(request)
    current_user = request.env['warden']&.user
    current_user&.user_object&.super_admin?
  end
end
