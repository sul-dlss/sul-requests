# frozen_string_literal: true

# get the current User object from the Rails request object
# Intended to be used as CurrentUser.for(request)
class CurrentUser
  attr_reader :request

  delegate :params, to: :request

  def initialize(request)
    @request = request
  end

  def self.for(request)
    new(request).user_object
  end

  def user_object
    @user_object ||= begin
      if user_id.present?
        sso_user
      else
        anonymous_user
      end
    end
  end

  private

  def sso_user
    User.find_or_create_by(sunetid: user_id).tap do |user|
      update_ldap_attributes(user)
    end
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
    return "#{user_id}@stanford.edu" if ldap_email_status == 'active'
  end

  def ldap_email_attribute
    ldap_attributes['mail']
  end

  def ldap_email_status
    ldap_attributes['suEmailStatus']
  end

  def ldap_attributes
    data = request.env
    data = data.merge(fake_ldap_attributes) if use_fake_ldap_attributes?
    data
  end

  def anonymous_user
    User.new(ip_address: request.remote_ip)
  end

  def user_id
    request.env['REMOTE_USER'].presence || ENV.fetch('REMOTE_USER', nil)
  end

  def fake_ldap_attributes
    return {} unless user_id && use_fake_ldap_attributes?

    (Settings.fake_ldap_attributes[user_id] || {}).to_hash.stringify_keys
  end

  # Only allow fake ldap information in development
  def use_fake_ldap_attributes?
    Settings.fake_ldap_attributes &&
      Settings.fake_ldap_attributes[user_id] &&
      Rails.env.development?
  end
end
