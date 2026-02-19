# frozen_string_literal: true

###
#  Ability class for authorizing Aeon-specific actions
###
class AeonAbility
  include CanCan::Ability

  # The CanCan DSL requires a complex initialization method
  def initialize(user)
    # Clearing CanCan's default aliased actions
    # because we _don't_ want to alias new to create
    clear_aliased_actions
    alias_action :index, :show, to: :read
    alias_action :edit, to: :update

    # anyone can start to create an Aeon page
    can [:new, :create], PatronRequest, &:aeon_page?

    can :destroy, Aeon::Request, username: user.email_address
    can :update, Aeon::Request do |request|
      request.username == user.email_address && request.writable?
    end

    return unless user.sso_user?

    can :read, Aeon::Request
    can :manage, Aeon::Appointment
  end
end
