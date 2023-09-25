# frozen_string_literal: true

###
#  Mixin to handle creating, encyrpting, and decrypting, and validating tokens for objects
###
module TokenEncryptable
  def to_token(version: 2)
    if version == 2
      (['v2'] + [id]).join('/')
    else
      token_encryptor_attributes.join
    end
  end

  def token_encryptor_attributes
    [id, created_at]
  end

  def encrypted_token
    @encrypted_token ||= TokenEncryptor.new(to_token).encrypt_and_sign
  end

  def valid_token?(token)
    TokenEncryptor.new(token).decrypt_and_verify == to_token
  end
end
