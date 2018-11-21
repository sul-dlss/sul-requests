# frozen_string_literal: true

require 'rails_helper'

###
#  Simple test class for testing methods mixed-in by TokenEncryptable
###
class TestEncryptorClass
  attr_accessor :id, :created_at, :new_attribute
  include TokenEncryptable
  def token_encryptor_attributes
    super << new_attribute
  end
end

describe TokenEncryptable do
  let(:subject) { TestEncryptorClass.new }
  before do
    subject.id = '123'
    subject.created_at = 'now'
  end
  describe 'to_token' do
    it 'should include id and created_at by default' do
      expect(subject.to_token).to eq '123now'
    end
    it 'shuold include attributes added by the class that is mixing in' do
      subject.new_attribute = 'my_new_attr'
      expect(subject.to_token).to eq '123nowmy_new_attr'
    end
  end
  describe 'token encryption' do
    let(:token) { subject.to_token }
    let(:encrypted_token) { subject.encrypted_token }
    describe 'encyrption' do
      it 'should return an encrypted_token longer than the original' do
        expect(encrypted_token.length).to be > token.length
      end
      it 'should be able to verify that a given encrypted token is valid' do
        expect(subject).to be_valid_token(encrypted_token)
      end
      it 'should raise an error when passed an invalid encrypted token' do
        expect(-> { subject.valid_token?(token) }).to raise_error(ActiveSupport::MessageVerifier::InvalidSignature)
      end
    end
  end
end
