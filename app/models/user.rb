# frozen_string_literal: true

###
#  User class for authenticating via WebAuth
###
class User < ActiveRecord::Base
  validates :webauth, uniqueness: true, allow_blank: true

  has_many :requests

  attr_writer :ldap_group_string, :affiliation
  attr_accessor :ip_address

  delegate :proxy?, :sponsor?, to: :proxy_access

  def to_email_string
    if name.present?
      "#{name} (#{email_address})"
    else
      email_address
    end
  end

  def sucard_number=(card_number)
    return unless card_number.present?

    self.library_id = card_number[/\d{5}(\d+)/, 1]
  end

  def library_id=(library_id)
    super(library_id.to_s.upcase)
  end

  def email_address
    case
    when library_id_user?
      email_from_symphony
    when webauth_user? && !email
      # Fallback for users who were created before we started
      # setting the email attribute for webauth users from LDAP
      notify_honeybadger_of_unknown_webauth_email!
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

  def super_admin?
    admin_groups = Settings.super_admin_groups || []
    (ldap_groups & admin_groups).present?
  end

  def site_admin?
    admin_groups = Settings.site_admin_groups || []
    (ldap_groups & admin_groups).present?
  end

  def admin_for_origin?(library_or_location)
    admin_groups = Settings.origin_admin_groups[library_or_location] || []
    (ldap_groups & admin_groups).present?
  end

  def ldap_groups
    (@ldap_group_string || '').split(/[|;]/)
  end

  def proxy_access
    @proxy_access ||= ProxyAccess.new(libid: library_id)
  end

  def affiliation
    (@affiliation || '').split(/[|;]/)
  end

  def student_type
    (super || '').split(/[|;]/)
  end

  def email_from_symphony
    self.email ||= begin
      SymphonyUserNameRequest.new(libid: library_id).email
    end if library_id_user?
  end

  private

  def notify_honeybadger_of_unknown_webauth_email!
    Honeybadger.notify(
      "Webauth user record being created without a valid email address. Using #{webauth}@stanford.edu instead."
    ) if new_record?
  end
end
