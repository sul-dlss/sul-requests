# frozen_string_literal: true

Warden::Strategies.add(:shibboleth) do
  def valid?
    uid.present?
  end

  def authenticate!
    response = FolioClient.new.login_by_sunetid(uid)

    if response&.key?('key') || response&.key?('id')
      u = { username: uid, patron_key: response['key'] || response['id'], shibboleth: true, ldap_attributes: }
      success!(u)
    else
      # even though we didn't find a patron record in the ILS, the Shibboleth auth was successful
      # so maybe we can do something with that...
      success!({ username: uid, shibboleth: true, ldap_attributes: })
    end
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

Warden::Strategies.add(:development_shibboleth_stub) do
  def valid?
    Rails.env.development? && uid.present?
  end

  def authenticate!
    response = FolioClient.new.login_by_sunetid(uid)

    if response&.key?('key') || response&.key?('id')
      u = { username: uid, patron_key: response['key'] || response['id'], shibboleth: true, ldap_attributes: }
      success!(u)
    else
      # even though we didn't find a patron record in the ILS, the Shibboleth auth was successful
      # so maybe we can do something with that...
      success!({ username: uid, shibboleth: true, ldap_attributes: })
    end
  end

  private

  def uid
    ENV.fetch('REMOTE_USER', nil)
  end

  def ldap_attributes
    (Settings.fake_ldap_attributes[uid] || {}).to_hash.stringify_keys
  end
end

Warden::Strategies.add(:library_id) do
  def valid?
    params['library_id'].present? && params['pin'].present?
  end

  def authenticate!
    response = FolioClient.new.login_by_library_id_and_pin(params['library_id'], params['pin'])

    if response&.key?('patronKey') || response&.key?('id')
      u = { username: params['library_id'], patron_key: response['patronKey'] || response['id'] }
      success!(u)
    else
      fail!('Could not log in')
    end
  end
end
