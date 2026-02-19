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

  def self.faculty
    @faculty ||= Ability.new(NullUser.new(sunetid: 'generic', placeholder_patron_group: 'faculty'))
  end

  def self.new(user)
    user ||= User.new

    SiteAbility.new(user).merge(PatronAbility.new(user.patron)).merge(AeonAbility.new(user.aeon))
  end
end
