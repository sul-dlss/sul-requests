# frozen_string_literal: true

Warden::Strategies.add(:shibboleth) do
  def valid?
    uid.present?
  end

  def authenticate!
    response = ApplicationController.ils_client_class.new.login_by_sunetid(uid)

    if response&.key?('key') || response&.key?('id')
      u = { username: uid, patron_key: response['key'] || response['id'], shibboleth: true }
      success!(u)
    else
      fail!('Could not log in')
    end
  end

  private

  def uid
    env['uid']
  end
end

Warden::Strategies.add(:development_shibboleth_stub) do
  def valid?
    Rails.env.development? && uid.present?
  end

  def authenticate!
    response = ApplicationController.ils_client_class.new.login_by_sunetid(uid)

    if response&.key?('key') || response&.key?('id')
      u = { username: uid, patron_key: response['key'] || response['id'] }
      success!(u)
    else
      fail!('Could not log in')
    end
  end

  private

  def uid
    ENV.fetch('uid', nil)
  end
end

Warden::Strategies.add(:library_id) do
  def valid?
    params['library_id'].present? && params['pin'].present?
  end

  def authenticate!
    response = ApplicationController.ils_client_class.new.login(params['library_id'], params['pin'])

    if response&.key?('patronKey') || response&.key?('id')
      u = { username: params['library_id'], patron_key: response['patronKey'] || response['id'] }
      success!(u)
    else
      fail!('Could not log in')
    end
  end
end
