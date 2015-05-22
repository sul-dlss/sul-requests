###
#  Main ability class for authorization
#  See the wiki for details about defining abilities:
#  https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
###
class Ability
  include CanCan::Ability

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  # The CanCan DSL requires a complex initialization method
  def initialize(user, token = nil)
    user ||= User.new
    @user = user
    # Claering CanCan's default aliased actions
    # because we don't want to alias new to create
    # CanCan's defaults are
    # alias_action :index, :show, to: :read
    # alias_action :new, to: :create
    # alias_action :edit, to: :update

    clear_aliased_actions
    alias_action :index, :show, to: :read
    alias_action :edit, to: :update
    # Adding new aliased action because
    # success has the same rules as status
    alias_action :status, to: :success

    can :manage, :all if user.superadmin?

    can :manage, Message if user.site_admin?
    can :manage, Request if user.site_admin?
    can :manage, LibraryLocation if user.site_admin?
    # Adminstrators for origins or destinations should be able to
    # manage requests originating or arriving to their library.
    can :manage, Request do |request|
      user.admin_for_origin?(request.origin)
    end

    can :manage, LibraryLocation do |library|
      user.admin_for_origin?(library.library)
    end

    can :new, Request

    can :create, Request do |_|
      user.webauth_user?
    end

    can :success, Request do |request|
      current_user_owns_request?(request)
    end

    can :success, Page do |page|
      page.valid_token?(token) if token
    end

    can :success, MediatedPage do |page|
      page.valid_token?(token) if token
    end

    can :create, Page do |page|
      request_is_by_anonymous_user?(page) && page.requestable_by_all?
    end

    can :create, Page do |page|
      request_is_by_library_id_user?(page) && page.requestable_with_library_id?
    end

    can :create, MediatedPage do |mediated_page|
      request_is_by_anonymous_user?(mediated_page) && mediated_page.requestable_by_all?
    end

    can :create, MediatedPage do |mediated_page|
      request_is_by_library_id_user?(mediated_page) && mediated_page.requestable_with_library_id?
    end

    # Only Webauth users can create scan requests (for now).
    cannot :create, Scan unless user.webauth_user?
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  def current_user_owns_request?(request)
    request.user_id == @user.id && @user.webauth_user?
  end

  def request_is_by_anonymous_user?(request)
    request.user && request.user.non_webauth_user?
  end

  def request_is_by_library_id_user?(request)
    request.user && request.user.library_id_user?
  end
end
