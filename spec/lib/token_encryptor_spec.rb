# frozen_string_literal: true

require 'rails_helper'

describe SULRequests::TokenEncryptor do
  let(:token) { 'token-123' }
  let(:subject) { SULRequests::TokenEncryptor }
  it 'should throw an error if there is no configured secret' do
    allow_any_instance_of(subject).to receive(:secret).and_return('')
    expect(-> { subject.new(token) }).to raise_error(SULRequests::TokenEncryptor::InvalidSecret)
  end
  it 'should throw an error if there is no configured salt' do
    allow_any_instance_of(subject).to receive(:salt).and_return('')
    expect(-> { subject.new(token) }).to raise_error(SULRequests::TokenEncryptor::InvalidSalt)
  end
  describe '#encrypt_and_sign' do
    it 'should return an encyrpted and signed message' do
      expect(subject.new(token).encrypt_and_sign).to include '==--'
      expect(subject.new(token).encrypt_and_sign.length).to be > token.length
    end
  end
  describe '#decrypt_and_verify' do
    let(:encrypted_token) { subject.new(token).encrypt_and_sign }
    it 'should decrypt and verify encrypted and signed messages' do
      expect(subject.new(encrypted_token).decrypt_and_verify).to eq token
    end
    it 'should raise an error if the token is not valid' do
      expect(
        -> { subject.new("1#{encrypted_token}").decrypt_and_verify }
      ).to raise_error(ActiveSupport::MessageVerifier::InvalidSignature)
    end
  end
end
