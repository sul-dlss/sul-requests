require 'rails_helper'

describe CurrentUser do
  let(:rails_req) { double(env: {}, remote_ip: '') }
  subject { described_class.for(rails_req) }
  describe '#current_user' do
    it 'should return nil user if there is no user in the environment' do
      expect(subject).to be_a User
      expect(subject).to_not be_persisted
      expect(subject.id).to be_nil
    end
    it 'should return a user when there is a user in the environment' do
      allow_any_instance_of(described_class).to receive_messages(user_id: 'some-user')
      expect(subject).to be_a User
      expect(subject.webauth).to eq 'some-user'
    end
    it 'should return the ldap groups as an array' do
      allow_any_instance_of(described_class).to receive_messages(user_id: 'some-user')
      ldap_attr = { 'WEBAUTH_LDAPPRIVGROUP' => 'ldap:group1|ldap:group2' }
      allow_any_instance_of(described_class).to receive_messages(ldap_attributes: ldap_attr)
      expect(subject.ldap_groups).to eq ['ldap:group1', 'ldap:group2']
    end
    it 'has the SUCARD Number id from LDAP and translates it to the library_id' do
      allow_any_instance_of(described_class).to receive_messages(user_id: 'some-user')
      allow(rails_req).to receive(:env).and_return('WEBAUTH_LDAP_SUCARDNUMBER' => '12345987654321')
      expect(subject).to be_a User
      expect(subject.library_id).to eq '987654321'
      expect(subject).not_to be_changed
    end

    describe 'email' do
      it 'is the WEBAUTH_EMAIL from ldap attributes' do
        allow_any_instance_of(described_class).to receive_messages(user_id: 'some-user')
        allow(rails_req).to receive(:env).and_return('WEBAUTH_EMAIL' => 'the-email@fromldap.edu')
        expect(subject.email).to eq 'the-email@fromldap.edu'
      end

      it 'is the "SUNet@stanford.edu" when there is no WEBAUTH_EMAIL and the WEBAUTH_LDAP_SUEMAILSTATUS is active' do
        allow_any_instance_of(described_class).to receive_messages(user_id: 'some-user')
        allow(rails_req).to receive(:env).and_return('WEBAUTH_LDAP_SUEMAILSTATUS' => 'active')
        expect(subject.email).to eq 'some-user@stanford.edu'
      end
    end

    describe 'ip address' do
      it 'is not applied to known webauth users as we do not care about their location' do
        allow_any_instance_of(described_class).to receive_messages(user_id: 'some-user')
        expect(subject.ip_address).to be_nil
      end

      it 'is applied to anonymous current users' do
        allow(rails_req).to receive(:remote_ip).and_return('1.22.333.444')
        expect(subject.ip_address).to eq '1.22.333.444'
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
