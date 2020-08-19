# frozen_string_literal: true

# Class to model Research group information
class Group < Patron

  def sponsor
    members.find(&:sponsor?)
  end

  private

  def members
    @members ||= begin
      members = fields.dig('groupSettings', 'fields', 'group', 'fields', 'memberList') || []
      members.map { |member| Patron.new(member) }
    end
  end
end
