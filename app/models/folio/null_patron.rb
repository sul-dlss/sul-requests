# frozen_string_literal: true

module Folio
  # Model for working with FOLIO Patron information
  class NullPatron
    attr_reader :user

    delegate :email, to: :user

    def initialize(user)
      @user = user
    end

    def display_name
      user.name
    end

    def patron_description
      'Visitor'
    end

    # this returns the full patronGroup object
    def patron_group
      Folio::Types.patron_groups[sul_purchased_patron_group_id]
    end

    def patron_group_id
      @patron_group_id ||= Folio::Types.patron_groups.select { |_k, v| v['group'] == 'sul-purchased' }.keys.first
    end

    def patron_group_name
      patron_group&.dig('group')
    end

    def patron_comments
      "#{display_name} <#{email}>"
    end

    def allowed_request_types(item)
      (policy_service.item_request_policy(item)&.dig('requestTypes') || []) & ['Page']
    end

    def policy_service
      @policy_service ||= Folio::CirculationRules::PolicyService.new(patron_groups: [patron_group_id])
    end

    def block_reasons
      []
    end

    # define the remaining methods of Folio::Patron
    (Folio::Patron.instance_methods(false) - instance_methods(false)).each do |method|
      define_method(method) do |*, **|
        nil
      end
    end
  end
end
