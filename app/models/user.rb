# frozen_string_literal: true

###
#  User class for authenticating via SSO
###
class User < ActiveRecord::Base
  validates :sunetid, uniqueness: true, allow_blank: true
  validates :univ_id, format: { with: /\A\d{8,10}\z/ }, allow_blank: true

  has_many :requests

  attr_writer :ldap_group_string, :affiliation
  attr_accessor :ip_address

  def proxy?
    patron&.proxy?
  end

  def sponsor?
    patron&.sponsor?
  end

  class_attribute :patron_model_class, default: Settings.ils.patron_model&.constantize || Folio::Patron

  def to_email_string
    if name.present?
      "#{name} (#{email_address})"
    else
      email_address
    end
  end

  # Prefer the patron university ID from the ILS, but fall back to the univ ID as-provided
  # so that the system can function when the ILS is offline
  def university_id
    patron&.university_id || univ_id
  end

  def email_address
    case
    when sso_user? && !email
      # Fallback for users who were created before we started
      # setting the email attribute for SSO users from LDAP
      notify_honeybadger_of_missing_sso_email!
      "#{sunetid}@stanford.edu"
    when univ_id_user?
      email_from_ils
    else
      email
    end
  end

  def sso_user?
    sunetid.present?
  end

  def univ_id_user?
    univ_id.present?
  end

  def name_email_user?
    name.present? && email.present?
  end

  def super_admin?
    admin_groups = Settings.super_admin_groups || []
    ldap_groups.intersect?(admin_groups)
  end

  def site_admin?
    admin_groups = Settings.site_admin_groups || []
    ldap_groups.intersect?(admin_groups)
  end

  def ldap_groups
    (@ldap_group_string || '').split(/[|;]/)
  end

  def affiliation
    (@affiliation || '').split(/[|;]/)
  end

  def student_type
    (super || '').split(/[|;]/)
  end

  def email_from_ils
    self.email ||= begin
      patron.email if univ_id_user? && patron.present?
    end
  end

  def patron
    @patron ||= begin
      if sso_user?
        patron_model_class.find_by(sunetid:)
      elsif univ_id_user?
        patron_model_class.find_by(univ_id:)
      end
    end
  end

  private

  def notify_honeybadger_of_missing_sso_email!
    Honeybadger.notify(
      "SSO User being created without an email address. Using #{sunetid}@stanford.edu instead."
    ) if new_record?
  end
end
