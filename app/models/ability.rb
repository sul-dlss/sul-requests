###
#  Main ability class for authorization
#  See the wiki for details about defining abilities:
#  https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
###
class Ability
  include CanCan::Ability

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
  # The CanCan DSL requires a complex initialization method
  def initialize(user)
    user ||= User.new

    # Claering CanCan's default aliased actions
    # because we don't want to alias new to create
    # CanCan's defaults are
    # alias_action :index, :show, to: :read
    # alias_action :new, to: :create
    # alias_action :edit, to: :update

    clear_aliased_actions
    alias_action :index, :show, to: :read
    alias_action :edit, to: :update

    can :manage, :all if user.superadmin?

    can :manage, Request if user.site_admin?
    # Adminstrators for origins or destinations should be able to
    # manage requests originating or arriving to their library.
    can :manage, Request do |request|
      user.admin_for_origin?(request.origin) ||
        user.admin_for_destination?(request.destination)
    end

    can :new, Request

    # Webauth users or users who provide a Name and Email can create requests
    can :create, Request do |_|
      user.webauth_user? # || (user.name.present? && user.email.present?)
    end

    # Only Webauth users can create scan requests (for now).
    cannot :create, Scan unless user.webauth_user?
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
