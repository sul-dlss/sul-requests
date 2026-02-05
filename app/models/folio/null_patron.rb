# frozen_string_literal: true

module Folio
  # Model for working with FOLIO Patron information
  class NullPatron
    def self.visitor_patron_group
      Folio::Types.patron_groups.find_by(group: 'visitor')
    end

    attr_reader :user

    def initialize(user = nil, display_name: nil, email: nil, patron_group_name: nil)
      @user = user
      @display_name = display_name
      @email = email
      @patron_group_name = patron_group_name || 'visitor'
    end

    def display_name
      @display_name || user.name
    end

    def email
      @email || user.email
    end

    # this returns the full patronGroup object
    def patron_group
      return @patron_group if defined?(@patron_group)

      @patron_group = Folio::Types.patron_groups.find_by(group: @patron_group_name)
      @patron_group ||= self.class.visitor_patron_group
    end

    def patron_description
      patron_group.desc
    end

    def patron_group_name
      patron_group.group
    end

    def patron_comments
      "#{display_name} <#{email}>"
    end

    def allowed_request_types(item)
      policy_service.item_request_policy(item)&.dig('requestTypes') || []
    end

    def policy_service
      @policy_service ||= Folio::CirculationRules::PolicyService.new(patron_groups: [patron_group_id])
    end

    def block_reasons
      []
    end

    def sponsors
      []
    end

    def proxies
      []
    end

    def present?
      false
    end

    def blank?
      true
    end

    # define the remaining methods of Folio::Patron
    (Folio::Patron.instance_methods(false) - instance_methods(false)).each do |method|
      define_method(method) do |*, **|
        nil
      end
    end

    private

    def patron_group_id
      patron_group.id
    end
  end
end
