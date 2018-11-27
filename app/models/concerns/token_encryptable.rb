# frozen_string_literal: true

###
#  Mixin to handle creating, encyrpting, and decrypting, and validating tokens for objects
###
module TokenEncryptable
  def to_token
    token_encryptor_attributes.join
  end

  def token_encryptor_attributes
    [id, created_at]
  end

  def encrypted_token
    @encrypted_token ||= SULRequests::TokenEncryptor.new(to_token).encrypt_and_sign
  end

  def valid_token?(token)
    SULRequests::TokenEncryptor.new(token).decrypt_and_verify == to_token
  end
end
