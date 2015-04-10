###
#  Main ability class for authorization
#  See the wiki for details about defining abilities:
#  https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
###
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    can :manage, :all if user.superadmin?

    can :manage, Request if user.site_admin?
    # Adminstrators for origins or destinations should be able to
    # manage requests originating or arriving to their library.
    can :manage, Request do |request|
      user.admin_for_origin?(request.origin) ||
        user.admin_for_destination?(request.destination)
    end

    # Everyone can create Page Requests (for now).
    can :create, Page
  end
end
