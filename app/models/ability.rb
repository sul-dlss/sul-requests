# frozen_string_literal: true

###
#  Main ability class for authorization
#  See the wiki for details about defining abilities:
#  https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
###
class Ability
  include CanCan::Ability

  def self.new(user)
    user ||= User.new

    SiteAbility.new(user)
  end
end
