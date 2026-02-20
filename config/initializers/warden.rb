# frozen_string_literal: true

Warden::Manager.serialize_into_session do |current_user|
  current_user.as_json
end

Warden::Manager.serialize_from_session do |json|
  CurrentUser.new(json)
end

# Warden authentication strategy for Shibboleth SSO
class ShibbolethStrategy < Warden::Strategies::Base
  def valid?
    uid.present?
  end

  def authenticate!
    success!(CurrentUser.new({ username: uid, shibboleth: true, ldap_attributes: }))
  end

  private

  def uid
    env['uid']
  end

  def ldap_attributes
    {
      'displayName' => env['displayName'],
      'eduPersonEntitlement' => env['eduPersonEntitlement'],
      'suUnivID' => env['suUnivID'],
      'suCardNumber' => env['suCardNumber'],
      'suAffiliation' => env['suAffiliation'],
      'suStudentType' => env['suStudentType'],
      'mail' => env['mail'],
      'suEmailStatus' => env['suEmailStatus']
    }
  end
end

# Warden authentication strategy for Shibboleth SSO in development
# set fake_ldap_attributes and pass REMOTE_USER when running to configure
class DevelopmentShibbolethStrategy < ShibbolethStrategy
  def valid?
    Rails.env.development? && uid.present?
  end

  private

  def uid
    ENV.fetch('REMOTE_USER', nil)
  end

  def ldap_attributes
    (Settings.fake_ldap_attributes[uid] || {}).to_hash.stringify_keys
  end
end

Warden::Strategies.add(:shibboleth, ShibbolethStrategy)

Warden::Strategies.add(:development_shibboleth_stub, DevelopmentShibbolethStrategy)

Warden::Strategies.add(:university_id) do
  def valid?
    params['university_id'].present? && params['pin'].present?
  end

  def authenticate!
    # TODO: change to login_by_university_id when we stop accepting barcodes
    user = FolioClient.new.login_by_barcode_or_university_id(params['university_id'], params['pin'])

    if user&.key?('patronKey') || user&.key?('id')
      u = { username: params['university_id'], patron_key: user['patronKey'] || user['id'] }
      success!(CurrentUser.new(u))
    else
      fail!('Could not log in')
    end
  end
end

# For visitor registration, information does not go through Shibboleth.
# The only authentication is ensuring the name and email fields are both present.
Warden::Strategies.add(:register_visitor) do
  def valid?
    params['name'].present? || params['patron_email'].present?
  end

  def authenticate!
    if params['name'].present? && params['patron_email'].present?
      u = { name: params['name'], email: params['patron_email'], shibboleth: false }
      success!(CurrentUser.new(u))
    else
      # TODO: Should there be specific wording to this error message?
      fail!('Please supply both name and email')
    end
  end
end
