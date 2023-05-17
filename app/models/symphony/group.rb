# frozen_string_literal: true

module Symphony
  # Class to model Research group information
  class Group < Symphony::Patron
    def sponsor
      members.find(&:sponsor?)
    end

    def email
      sponsor&.email
    end

    def name
      sponsor&.display_name
    end

    private

    def members
      @members ||= begin
        members = fields.dig('groupSettings', 'fields', 'group', 'fields', 'memberList') || []
        members.map { |member| Symphony::Patron.new(member) }
      end
    end
  end
end
