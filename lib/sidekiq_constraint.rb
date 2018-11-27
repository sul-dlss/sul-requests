# frozen_string_literal: true

# determine if current user is allowed to see sidekiq pages
class SidekiqConstraint
  def matches?(request)
    current_user = CurrentUser.for(request)
    current_user&.super_admin?
  end
end
