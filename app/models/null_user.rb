# frozen_string_literal: true

###
#  User class for authenticating via SSO
###
class NullUser
  attr_reader :name, :email, :library_id, :sunetid, :placeholder_patron_group

  def initialize(name: nil, email: nil, library_id: nil, sunetid: nil, placeholder_patron_group: nil)
    @name = name
    @email = email
    @library_id = library_id
    @sunetid = sunetid
    @placeholder_patron_group = placeholder_patron_group
  end

  def id = nil

  def proxy?
    false
  end

  def sponsor?
    false
  end

  def to_email_string
    ''
  end

  def barcode
    library_id
  end

  def university_id
    univ_id
  end

  def email_address
    email
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

  def super_admin? = false
  def site_admin? = false
  def ldap_groups = []
  def affiliation = []
  def student_type = []
  def email_from_symphony = nil

  def patron
    placeholder_patron
  end

  def aeon
    @aeon ||= Aeon::NullUser.new
  end

  private

  def placeholder_patron
    @placeholder_patron ||= Folio::NullPatron.new(self, patron_group_name: @placeholder_patron_group)
  end
end
