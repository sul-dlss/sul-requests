# frozen_string_literal: true

# get the current User object from the Rails request object
class CurrentUser
  attr_reader :data

  def initialize(data)
    @data = (data || {}).with_indifferent_access
  end

  def as_json(...)
    data.as_json(...)
  end

  def user_object
    @user_object ||= begin
      if shibboleth?
        sso_user
      elsif library_id?
        library_id_user
      elsif name_email_user?
        name_email_user
      else
        anonymous_user
      end
    end
  end

  def shibboleth?
    data['shibboleth']
  end

  def name_email_user?
    data['name'].present? && data['email'].present?
  end

  private

  def library_id?
    return false if shibboleth?

    data['patron_key']
  end

  def sso_user
    User.find_or_create_by(sunetid: user_id).tap do |user|
      update_ldap_attributes(user)
      update_folio_attributes(user)
    end
  end

  def library_id_user
    User.find_or_create_by(library_id: user_id).tap do |user|
      update_folio_attributes(user)
    end
  end

  def name_email_user
    User.new(name: data['name'], email: data['email'])
  end

  # rubocop:disable Metrics/AbcSize
  def update_ldap_attributes(user)
    user.name = ldap_name
    user.ldap_group_string = ldap_group_string
    user.sucard_number = ldap_sucard_number
    user.univ_id = ldap_univ_id
    user.affiliation = ldap_affiliation
    user.email = ldap_email
    user.student_type = ldap_student_type

    user.save if user.changed?
  end
  # rubocop:enable Metrics/AbcSize

  def update_folio_attributes(user)
    user.patron_key = data['patron_key']
  end

  def ldap_attributes
    data['ldap_attributes'] || {}
  end

  def ldap_name
    ldap_attributes['displayName']
  end

  def ldap_group_string
    ldap_attributes['eduPersonEntitlement']
  end

  def ldap_univ_id
    ldap_attributes['suUnivID']
  end

  def ldap_sucard_number
    ldap_attributes['suCardNumber']
  end

  def ldap_affiliation
    ldap_attributes['suAffiliation']
  end

  def ldap_student_type
    ldap_attributes['suStudentType']
  end

  def ldap_email
    return ldap_email_attribute unless ldap_email_attribute.nil?

    "#{user_id}@stanford.edu" if ldap_email_status == 'active'
  end

  def ldap_email_attribute
    ldap_attributes['mail']
  end

  def ldap_email_status
    ldap_attributes['suEmailStatus']
  end

  def anonymous_user
    User.new
  end

  def user_id
    data['username']
  end
end
