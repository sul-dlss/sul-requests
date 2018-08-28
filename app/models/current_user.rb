# get the current User object from the Rails request object
# Intended to be used as CurrentUser.for(request)
class CurrentUser
  attr_reader :request

  def initialize(request)
    @request = request
  end

  def self.for(request)
    new(request).user_object
  end

  def user_object
    @user_object ||= begin
      if user_id.present?
        webauth_user
      else
        anonymous_user
      end
    end
  end

  private

  def webauth_user
    User.find_or_create_by(webauth: user_id).tap do |user|
      update_ldap_attributes(user)
    end
  end

  def update_ldap_attributes(user)
    user.name = ldap_name
    user.ldap_group_string = ldap_group_string
    user.sucard_number = ldap_sucard_number
    user.affiliation = ldap_affiliation
    user.email = ldap_email
    user.save if user.changed?
  end

  def ldap_name
    ldap_attributes['WEBAUTH_LDAP_DISPLAYNAME'] || ldap_attributes['displayName']
  end

  def ldap_group_string
    ldap_attributes['WEBAUTH_LDAPPRIVGROUP'] || ldap_attributes['eduPersonEntitlement']
  end

  def ldap_sucard_number
    ldap_attributes['WEBAUTH_LDAP_SUCARDNUMBER'] || ldap_attributes['suCardNumber']
  end

  def ldap_affiliation
    ldap_attributes['WEBAUTH_LDAP_SUAFFILIATION'] || ldap_attributes['suAffiliation']
  end

  def ldap_email
    return ldap_email_attribute unless ldap_email_attribute.nil?
    return "#{user_id}@stanford.edu" if ldap_email_status == 'active'
  end

  def ldap_email_attribute
    ldap_attributes['WEBAUTH_EMAIL'] || ldap_attributes['mail']
  end

  def ldap_email_status
    ldap_attributes['WEBAUTH_LDAP_SUEMAILSTATUS'] || ldap_attributes['suEmailStatus']
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
    request.env['REMOTE_USER'] || ENV['REMOTE_USER']
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
