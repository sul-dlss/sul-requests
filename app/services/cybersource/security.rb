# frozen_string_literal: true

module Cybersource
  # Methods for encoding and decoding transaction data
  # See the PDF linked in the README for more information
  class Security
    class InvalidSignature < StandardError; end

    class << self
      # Cybersource uses a base64 encoded HMAC SHA256 digest to sign the data
      def generate_signature(data)
        payload = data.map { |key, value| "#{key}=#{value}" }.join(',')
        Base64.encode64(OpenSSL::HMAC.digest('sha256', secret_key, payload)).strip
      end

      # If the signature matches the data, we know it hasn't been tampered with
      def valid_signature?(signature, data)
        generate_signature(data) == signature
      end

      # Raise an error if the signature doesn't match the data
      def validate_signature!(signature, data)
        raise InvalidSignature unless valid_signature?(signature, data)
      end

      private

      def secret_key
        Settings.cybersource.secret_key
      end
    end
  end
end
