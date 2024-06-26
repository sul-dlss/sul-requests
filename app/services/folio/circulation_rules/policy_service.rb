# frozen_string_literal: true

module Folio
  module CirculationRules
    # Evaluate the circulation rules to return the appropriate policies for a given item
    class PolicyService
      # Load the circulation rules file and parse it into a set of ordered rules
      def self.rules(rules_as_text = Folio::Types.circulation_rules)
        rules = Folio::CirculationRules::Transform.new.apply(Folio::CirculationRules::Parser.new.parse(rules_as_text))
        rules.map.with_index do |rule, index|
          rule.priority = index
          rule
        end
      end

      def self.standard_patron_group_uuids(group_names = Settings.folio.standard_patron_group_names)
        @standard_patron_group_uuids ||= Folio::Types.patron_groups.select { |_k, v| group_names.include? v['group'] }.keys
      end

      def self.instance
        @instance ||= new
      end

      attr_reader :rules, :policies, :patron_groups

      # Provide custom rules and policies or use the defaults
      def initialize(rules: nil, policies: nil, patron_groups: nil)
        @rules = rules || self.class.rules
        @policies = policies || Folio::Types.policies
        @patron_groups = patron_groups || self.class.standard_patron_group_uuids
      end

      def to_debug_s
        rules.map(&:to_debug_s).join("\n")
      end

      # Return the request policy for the given Holdings::Item
      def item_request_policy(item)
        rule = item_rule(item)
        @policies[:request].fetch(rule.policy['request'], nil)
      end

      # Return the loan policy for the given Holdings::Item
      def item_loan_policy(item)
        rule = item_rule(item)
        @policies[:loan].fetch(rule.policy['loan'], nil)
      end

      # Return the overdue fine policy for the given Holdings::Item
      def item_overdue_policy(item)
        rule = item_rule(item)
        @policies[:overdue].fetch(rule.policy['overdue'], nil)
      end

      # Return the lost item policy for the given Holdings::Item
      def item_lost_policy(item)
        rule = item_rule(item)
        @policies[:'lost-item'].fetch(rule.policy['lost-item'], nil)
      end

      # Return the patron notice policy for the given Holdings::Item
      def item_notice_policy(item)
        rule = item_rule(item)
        @policies[:notice].fetch(rule.policy['notice'], nil)
      end

      # Find the circulation rule that applies to the given Holdings::Item
      def item_rule(item)
        index.search('material-type' => item.material_type.id,
                     'loan-type' => item.loan_type.id,
                     'location-institution' => item.effective_location.institution.id,
                     'location-campus' => item.effective_location.campus.id,
                     'location-library' => item.effective_location.library.id,
                     'location-location' => item.effective_location.id,
                     'group' => @patron_groups)
      end

      def index
        @index ||= Folio::CirculationRules::Index.new(@rules)
      end
    end
  end
end
