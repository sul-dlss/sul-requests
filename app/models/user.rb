###
#  User class for authenticating via WebAuth
###
class User < ActiveRecord::Base
  validates :webauth, uniqueness: true, allow_blank: true

  has_many :requests

  attr_writer :ldap_group_string, :affiliation

  delegate :proxy?, :sponsor?, to: :proxy_access

  def to_email_string
    if non_webauth_user?
      "#{name} (#{email_address})"
    else
      email_address
    end
  end

  def sucard_number=(card_number)
    return unless card_number.present?
    self.library_id = card_number[/\d{5}(\d+)/, 1]
  end

  def email_address
    case
    when library_id_user?
      email_from_symphony
    when webauth_user?
      "#{webauth}@stanford.edu"
    else
      email
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

  def proxy_access
    @proxy_access ||= ProxyAccess.new(libid: library_id)
  end

  def affiliation
    (@affiliation || '').split('|')
  end

  def email_from_symphony
    self.email ||= begin
      SymphonyUserNameRequest.new(libid: library_id).email
    end if library_id_user?
  end
end
