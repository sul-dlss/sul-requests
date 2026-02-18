# frozen_string_literal: true

###
#  Ability class for authorizing site-level actions for admins
###
class SiteAbility
  include CanCan::Ability

  # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
  # The CanCan DSL requires a complex initialization method
  def initialize(user)
    # Clearing CanCan's default aliased actions
    # because we _don't_ want to alias new to create
    clear_aliased_actions
    alias_action :index, :show, to: :read
    alias_action :edit, to: :update

    if user.super_admin?
      can :manage, :site
      can :read, :admin
      can [:create, :read, :update, :destroy], :all
      can :manage, [LibraryLocation, Message, PagingSchedule, AdminComment]
      can [:admin, :debug], PatronRequest
    end

    if user.site_admin?
      can :read, :admin
      can :manage, [LibraryLocation, Message, PagingSchedule, AdminComment]
      can [:admin, :debug, :create, :read, :update, :destroy], PatronRequest
    end

    # Adminstrators for origins or destinations should be able to
    # manage requests originating or arriving to their library.

    admin_libraries = Settings.origin_admin_groups.to_h.select { |_k, v| user.ldap_groups.intersect?(v) }.keys.map(&:to_s)
    admin_locations = Settings.origin_location_admin_groups.to_h.select { |_k, v| user.ldap_groups.intersect?(v) }.keys.map(&:to_s)

    if admin_libraries.any?
      can :read, :admin
      can :manage, LibraryLocation, library: admin_libraries
      can :create, AdminComment, request: { origin_location_code: admin_libraries.flat_map do |x|
        Folio::Types.libraries.find_by(code: x)&.locations&.map(&:code) || []
      rescue StandardError
        []
      end }
      can [:admin, :read, :update], PatronRequest do |request|
        request.origin_library_code.in?(admin_libraries)
      end
    end

    if admin_locations.any? # rubocop:disable Style/GuardClause
      can :read, :admin
      can :manage, LibraryLocation, location: admin_locations
      can :create, AdminComment, request: { origin_location_code: admin_locations }
      can [:admin, :read, :update], PatronRequest, origin_location_code: admin_locations
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
end
