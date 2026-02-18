# frozen_string_literal: true

###
#  Ability class for authorizing FOLIO patron actions
###
class PatronAbility
  include CanCan::Ability

  # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
  # The CanCan DSL requires a complex initialization method
  def initialize(user)
    # Clearing CanCan's default aliased actions
    # because we _don't_ want to alias new to create
    clear_aliased_actions
    alias_action :index, :show, to: :read
    alias_action :edit, to: :update

    can :new, PatronRequest do |request|
      can?(:request_pickup, request) || can?(:request_scan, request)
    end

    can :create, PatronRequest do |request|
      request.selected_items.all? { |item| request.scan? ? can?(:scan, item) : can?(:request, item) }
    end

    # anyone can create title-level requests
    can :create, PatronRequest do |request|
      request.bib_data.items.none?
    end

    can :read, [PatronRequest], patron_id: user.patron.id if user.patron

    can :request, Folio::Item do |item|
      allowed_request_types = user.patron&.allowed_request_types(item) || []
      item.requestable?(request_types: allowed_request_types)
    end

    can :request_pickup, PatronRequest do |request|
      request.selectable_items.any? do |item|
        can?(:request, item)
      end
    end

    if user.library_id_user? || user.sso_user?
      can :request_pickup, PatronRequest do |request|
        request.bib_data.items.none?
      end
    end

    if user.super_admin? || in_scan_pilot_group?(user) # rubocop:disable Style/GuardClause
      can :scan, Folio::Item, &:scannable?

      can :request_scan, PatronRequest do |request|
        request.selectable_items.any? do |item|
          can? :scan, item
        end
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength

  def in_scan_pilot_group?(user)
    Settings.folio.scan_pilot_groups.include?(user.patron.patron_group_name)
  end
end
