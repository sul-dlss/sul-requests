# frozen_string_literal: true

###
#  Main ability class for authorization
#  See the wiki for details about defining abilities:
#  https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
###
class Ability
  include CanCan::Ability

  def self.anonymous
    @anonymous ||= Ability.new(User.new(name: 'generic', email: 'external-user@example.com'))
  end

  def self.with_a_library_id
    @with_a_library_id ||= Ability.new(User.new(library_id: '0000000000'))
  end

  def self.sso
    @sso ||= Ability.new(User.new(sunetid: 'generic'))
  end

  # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
  # The CanCan DSL requires a complex initialization method
  def initialize(user, token = nil)
    user ||= User.new

    # Claering CanCan's default aliased actions
    # because we don't want to alias new to create
    # CanCan's defaults are
    # alias_action :index, :show, to: :read
    # alias_action :new, to: :create
    # alias_action :edit, to: :update

    clear_aliased_actions
    alias_action :index, :show, :status, :success, to: :read
    alias_action :edit, to: :update

    if user.super_admin?
      can :manage, :site
      can [:create, :read, :update, :destroy], :all
      can :manage, [LibraryLocation, Message, PagingSchedule, Request, AdminComment]
    end

    if user.site_admin?
      can :manage, [LibraryLocation, Message, PagingSchedule, Request, AdminComment]
      can [:create, :read, :update, :destroy], [PatronRequest]
    end

    # Adminstrators for origins or destinations should be able to
    # manage requests originating or arriving to their library.

    admin_libraries = Settings.origin_admin_groups.to_h.select { |_k, v| user.ldap_groups.intersect?(v) }.keys.map(&:to_s)
    admin_locations = Settings.origin_location_admin_groups.to_h.select { |_k, v| user.ldap_groups.intersect?(v) }.keys.map(&:to_s)

    if admin_libraries.any?
      can :manage, LibraryLocation, library: admin_libraries
      can :create, AdminComment, request: { origin: admin_libraries }
      can :manage, Request, origin: admin_libraries
    end

    if admin_locations.any?
      can :manage, LibraryLocation, location: admin_locations
      can :create, AdminComment, request: { origin_location: admin_locations }
      can :manage, Request, origin_location: admin_locations
    end

    # Anyone can start the process of creating a request, because we haven't (necessarily)
    # authenticated them at the start of the request flow
    can :new, Request

    # ... but only some types of users can actually submit the request successfully
    if user.sso_user? || user.library_id_user? || user.name_email_user?
      can :create, MediatedPage
      can :create, Page
    end

    if user.name_email_user? && !user.library_id_user?
      cannot :create, Page, origin: 'BUSINESS'
      cannot :create, Page, origin: 'MEDIA-MTXT'
      cannot :create, Page, origin: 'MEDIA-CENTER'
    end

    can :create, HoldRecall if user.library_id_user? || user.sso_user?
    can :create, Scan if user.super_admin? || in_scan_pilot_group?(user)

    # ... and to check the status, you either need to be logged in or include a special token in the URL
    can :read, [Request, Page, HoldRecall, Scan, MediatedPage], user_id: user.id if user.sso_user?

    can :new, PatronRequest
    can :create, PatronRequest do |request|
      request.selected_items.all? { |item| can?((request.scan? ? :scan : :request), item) }
    end

    # anyone can create title-level requests
    can :create, PatronRequest do |request|
      request.selected_items.none?
    end

    # anyone can start to create an Aeon page
    can :create, PatronRequest, &:aeon_page?
    can :read, [PatronRequest], patron_id: user.patron.id if user.patron

    can :request, Folio::Item do |item|
      allowed_request_types = user.patron&.allowed_request_types(item) || []
      item.requestable?(request_types: allowed_request_types)
    end

    if user.super_admin? || in_scan_pilot_group?(user)
      can :scan, Folio::Item, &:scannable?

      can :request_scan, PatronRequest do |request|
        # For title level requests, follow a different path to assess scannability
        if request.title_only?
          request.title_only_scannable?
        else
          request.items_in_location.any? do |item|
            can? :scan, item
          end
        end
      end
    end

    can :prepare, PatronRequest do |request|
      request.items_in_location.any? do |item|
        can? :request, item
      end
    end

    if user.library_id_user? || user.sso_user?
      can :prepare, PatronRequest do |request|
        request.bib_data.items.none?
      end
    end

    if token
      begin
        token, = TokenEncryptor.new(token).decrypt_and_verify

        if token.starts_with? 'v2/'
          _v, id, _date = token.split('/', 3)
          can :read, [Request, Page, HoldRecall, Scan, MediatedPage], id: id.to_i
        else
          can :read, Request do |request|
            request.to_token(version: 1) == token
          end
        end
      rescue StandardError => _e
        # we don't care if the token is invalid
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength

  def in_scan_pilot_group?(user)
    user.affiliation.any? { |g| Settings.scan_pilot_groups.include? g }
  end
end
