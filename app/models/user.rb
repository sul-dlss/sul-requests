###
#  User class for authenticating via WebAuth
###
class User < ActiveRecord::Base
  validates :webauth, uniqueness: true, allow_blank: true

  has_many :requests

  attr_writer :ldap_group_string

  def to_email_string
    case
    when library_id_user?
      ''
    when webauth_user?
      "#{webauth}@stanford.edu"
    else
      "#{name} (#{email})"
    end
  end

  def webauth_user?
    webauth.present?
  end

  def non_webauth_user?
    !webauth_user? && name.present? && email.present?
  end

  def library_id_user?
    !webauth_user? && library_id.present?
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

  def ldap_groups
    (@ldap_group_string || '').split('|')
  end
end
