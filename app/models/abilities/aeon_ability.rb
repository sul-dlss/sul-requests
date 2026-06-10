# frozen_string_literal: true

###
#  Ability class for authorizing Aeon-specific actions
###
class AeonAbility
  include CanCan::Ability

  # The CanCan DSL requires a complex initialization method
  def initialize(aeon_user) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    # Clearing CanCan's default aliased actions
    # because we _don't_ want to alias new to create
    clear_aliased_actions
    alias_action :index, :show, to: :read
    alias_action :edit, to: :update

    return unless aeon_user.persisted?

    can [:new, :create], Aeon::Request

    can :destroy, Aeon::Request do |request|
      owner?(aeon_user:, record: request) || member_of_request_activity?(aeon_user:, request:)
    end
    can :update, Aeon::Request do |request|
      (owner?(aeon_user:, record: request) || member_of_request_activity?(aeon_user:, request:)) &&
        (request.saved_for_later? || request.appointment&.editable? || request.cancelled?)
    end

    can :read, Aeon::Activity
    can :read, Aeon::Request

    can :create, Aeon::Appointment
    can [:read, :destroy], Aeon::Appointment do |appointment|
      owner?(aeon_user:, record: appointment)
    end
    can :update, Aeon::Appointment do |appointment|
      owner?(aeon_user:, record: appointment) && appointment.editable?
    end
  end

  private

  def member_of_request_activity?(aeon_user:, request:)
    request.activity&.users&.include?(aeon_user)
  end

  def owner?(aeon_user:, record:)
    record.username == aeon_user.username
  end
end
