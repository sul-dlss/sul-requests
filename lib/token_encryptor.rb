# frozen_string_literal: true

###
#  Class to encrypt and decrypt messages using ActiveSupport::MessageEncryptor
#  This class requires that a secret and a salt are configured. These two configured
#  strings should be of moderate complexity and randomness.
#  If these configured keys change they will break any existing tokens given out.
#
#  Simple Usage:
#  encrypted_token = TokenEncryptor.new('abc-123').encrypt_and_sign
#  TokenEncryptor.new(encrypted_token).decrypt_and_verify
#  => "abc-123"
###
class TokenEncryptor
  def initialize(token)
    raise InvalidSecret unless secret.present?
    raise InvalidSalt unless salt.present?

    @token = token
  end

  def encrypt_and_sign
    encryptor.encrypt_and_sign(@token)
  end

  def decrypt_and_verify
    encryptor.decrypt_and_verify(@token)
  end

  private

  def key
    ActiveSupport::KeyGenerator.new(secret).generate_key(salt)[0..(ActiveSupport::MessageEncryptor.key_len - 1)]
  end

  def old_key
    ActiveSupport::KeyGenerator.new(secret).generate_key(salt)
  end

  def encryptor
    @encryptor ||= ActiveSupport::MessageEncryptor.new(key).tap do |crypt|
      crypt.rotate old_key
    end
  end

  def secret
    Settings.token_encrypt['secret']
  end

  def salt
    Settings.token_encrypt['salt']
  end

  class InvalidSecret < StandardError
  end

  class InvalidSalt < StandardError
  end
end
