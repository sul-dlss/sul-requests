# frozen_string_literal: true

###
#  Ability class for authorizing Aeon-specific actions
###
class AeonAbility
  include CanCan::Ability

  # The CanCan DSL requires a complex initialization method
  def initialize(aeon_user)
    # Clearing CanCan's default aliased actions
    # because we _don't_ want to alias new to create
    clear_aliased_actions
    alias_action :index, :show, to: :read
    alias_action :edit, to: :update

    return unless aeon_user.persisted?

    can [:new, :create], Aeon::Request

    can :destroy, Aeon::Request, username: aeon_user.username
    can :update, Aeon::Request do |request|
      request.username == aeon_user.username && request.writable?
    end

    can :read, Aeon::Request
    can :manage, Aeon::Appointment
  end
end
