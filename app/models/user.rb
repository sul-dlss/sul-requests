###
#  User class for authenticating via WebAuth
###
class User < ActiveRecord::Base
  def webauth_user?
    webauth.present?
  end
end
