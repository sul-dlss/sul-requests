###
#  User class for authenticating via WebAuth
###
class User < ActiveRecord::Base
  def webauth_user?
    webauth.present?
  end

  def superadmin?
    admin_groups = Settings.super_admin_groups || []
    (ldap_groups & admin_groups).present?
  end

  def site_admin?
    admin_groups = Settings.site_admin_groups || []
    (ldap_groups & admin_groups).present?
  end

  def admin_for_origin?(origin)
    admin_groups = Settings.origin_admin_groups[origin] || []
    (ldap_groups & admin_groups).present?
  end

  def admin_for_destination?(destination)
    admin_groups = Settings.destination_admin_groups[destination] || []
    (ldap_groups & admin_groups).present?
  end

  def ldap_groups
    (ENV['WEBAUTH_LDAPPRIVGROUP'] || '').split('|')
  end
end
