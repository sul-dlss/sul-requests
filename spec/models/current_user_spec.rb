# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurrentUser do
  subject { described_class.for(rails_req) }

  let(:rails_req) { double(env: {}) }

  describe '#current_user' do
    it 'returns nil user if there is no user in the environment' do
      expect(subject).to be_a User
      expect(subject).not_to be_persisted
      expect(subject.id).to be_nil
    end

    it 'returns a user when there is a user in the environment' do
      allow_any_instance_of(described_class).to receive_messages(user_id: 'some-user')
      expect(subject).to be_a User
      expect(subject.sunetid).to eq 'some-user'
    end

    it 'returns the ldap groups as an array' do
      allow_any_instance_of(described_class).to receive_messages(user_id: 'some-user')
      ldap_attr = { 'eduPersonEntitlement' => 'ldap:group1|ldap:group2' }
      allow_any_instance_of(described_class).to receive_messages(ldap_attributes: ldap_attr)
      expect(subject.ldap_groups).to eq ['ldap:group1', 'ldap:group2']
    end

    it 'has the suCardNumber id from LDAP and translates it to the library_id' do
      allow_any_instance_of(described_class).to receive_messages(user_id: 'some-user')
      allow(rails_req).to receive(:env).and_return('suCardNumber' => '12345987654321')
      expect(subject).to be_a User
      expect(subject.library_id).to eq '987654321'
      expect(subject).not_to be_changed
    end

    describe 'email' do
      it 'is the mail from ldap attributes' do
        allow_any_instance_of(described_class).to receive_messages(user_id: 'some-user')
        allow(rails_req).to receive(:env).and_return('mail' => 'the-email@fromldap.edu')
        expect(subject.email).to eq 'the-email@fromldap.edu'
      end

      it 'is the "SUNet@stanford.edu" when there is no mail and the suEmailStatus is active' do
        allow_any_instance_of(described_class).to receive_messages(user_id: 'some-user')
        allow(rails_req).to receive(:env).and_return('suEmailStatus' => 'active')
        expect(subject.email).to eq 'some-user@stanford.edu'
      end
    end
  end

  describe '#ldap_attributes' do
    it 'uses the request env' do
      rails_req = double(env: { 'a' => 1 })
      class_instance = described_class.new(rails_req)
      expect(class_instance.send(:ldap_attributes)).to include 'a' => 1
    end

    it 'enriches the request env with local settings' do
      allow_any_instance_of(described_class).to receive_messages(user_id: 'some-user')
      rails_req = double(env: { 'a' => 1 })
      allow(Rails.env).to receive(:development?).and_return(true)
      Settings.fake_ldap_attributes ||= {}
      allow(Settings).to receive(:fake_ldap_attributes).and_return('some-user' => { 'b' => 2 })
      class_instance = described_class.new(rails_req)
      expect(class_instance.send(:ldap_attributes)).to include 'a' => 1, 'b' => 2
    end
  end
end
