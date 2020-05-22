# frozen_string_literal: true

###
#  Main ability class for authorization
#  See the wiki for details about defining abilities:
#  https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
###
class Ability
  include CanCan::Ability

  # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
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

    can :manage, :all if user.super_admin?

    [LibraryLocation, Message, PagingSchedule, Request].each do |kind|
      can :manage, kind if user.site_admin?
    end

    # Adminstrators for origins or destinations should be able to
    # manage requests originating or arriving to their library.
    can :manage, Request do |request|
      user.admin_for_origin?(request.origin) || user.admin_for_origin?(request.origin_location)
    end

    can :manage, LibraryLocation do |library|
      user.admin_for_origin?(library.library) || user.admin_for_origin?(library.location)
    end

    can :new, Request

    can :create, Request do |_|
      user.webauth_user?
    end

    can :success, Request do |request|
      current_user_owns_request?(request)
    end

    [HoldRecall, MediatedPage, Page].each do |request_type|
      can :success, request_type do |request|
        request.valid_token?(token) if token
      end

      can :create, request_type do |request|
        request_is_by_anonymous_user?(request) && request.requestable_by_all?
      end

      can :create, request_type do |request|
        request_is_by_library_id_user?(request) && request.requestable_with_library_id?
      end
    end

    can :create, AdminComment do |admin_comment|
      can? :manage, admin_comment.request
    end

    cannot :create, Scan unless user.super_admin? || current_user_in_scan_pilot_group?
  end
  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength

  def current_user_owns_request?(request)
    request.user_id == @user.id && @user.webauth_user?
  end

  def current_user_in_scan_pilot_group?
    @user.affiliation.any? { |g| Settings.scan_pilot_groups.include? g }
  end

  def request_is_by_anonymous_user?(request)
    request.user&.non_webauth_user?
  end

  def request_is_by_library_id_user?(request)
    request.user&.library_id_user?
  end
end
