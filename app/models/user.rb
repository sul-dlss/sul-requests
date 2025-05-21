# frozen_string_literal: true

###
#  User class for authenticating via SSO
###
class User < ActiveRecord::Base
  validates :sunetid, uniqueness: true, allow_blank: true

  has_many :requests

  attr_writer :ldap_group_string, :affiliation
  attr_accessor :ip_address, :patron_key

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

  def sucard_number=(card_number)
    return unless card_number.present?

    self.library_id = card_number[/\d{5}(\d+)/, 1]
  end

  # Prefer the patron id from the ILS, but fall back to the library ID as-provided
  # so that the system can function when the ILS is offline
  def barcode
    patron&.library_id || library_id
  end

  # Prefer the patron information from the ILS, but fall back to the univ ID
  # so that the system can function when the ILS is offline
  def university_id
    patron&.university_id || univ_id
  end

  def library_id=(library_id)
    super(library_id.to_s.upcase)
  end

  def email_address
    case
    when sso_user? && !email
      # Fallback for users who were created before we started
      # setting the email attribute for SSO users from LDAP
      notify_honeybadger_of_missing_sso_email!
      "#{sunetid}@stanford.edu"
    when library_id_user?
      email_from_symphony
    else
      email
    end
  end

  def sso_user?
    sunetid.present?
  end

  def library_id_user?
    library_id.present?
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

  def email_from_symphony
    self.email ||= begin
      patron.email if library_id_user? && patron.present?
    end
  end

  def patron
    @patron ||= begin
      folio_patron = if patron_key.present?
                       patron_model_class.find_by(patron_key:)
                     elsif sso_user?
                       patron_model_class.find_by(sunetid:)
                     elsif library_id_user?
                       patron_model_class.find_by(library_id:)
                     end
      folio_patron || placeholder_patron
    end
  end

  private

  def placeholder_patron
    @placeholder_patron ||= Folio::NullPatron.new(self)
  end

  def notify_honeybadger_of_missing_sso_email!
    Honeybadger.notify(
      "SSO User being created without an email address. Using #{sunetid}@stanford.edu instead."
    ) if new_record?
  end
end
