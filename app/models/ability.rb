# frozen_string_literal: true

###
#  Main ability class for authorization
#  See the wiki for details about defining abilities:
#  https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
###
class Ability
  include CanCan::Ability

  def self.anonymous
    @anonymous ||= Ability.new(NullUser.new(name: 'generic', email: 'external-user@example.com'))
  end

  def self.with_a_library_id
    @with_a_library_id ||= Ability.new(NullUser.new(library_id: '0000000000'))
  end

  def self.sso
    @sso ||= Ability.new(NullUser.new(sunetid: 'generic'))
  end

  def self.faculty
    @faculty ||= Ability.new(NullUser.new(sunetid: 'generic', placeholder_patron_group: 'faculty'))
  end

  def self.new(user)
    user ||= User.new

    SiteAbility.new(user).merge(PatronAbility.new(user)).merge(AeonAbility.new(user))
  end
end
