# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurrentUser do
  subject { described_class.for(rails_req) }

  let(:rails_req) { double(env: { 'warden' => warden }) }
  let(:warden) do
    instance_double(Warden::Proxy, user: user&.stringify_keys)
  end
  let(:user) { nil }

  describe '#current_user' do
    context 'without a user in the environment' do
      let(:user) { nil }

      it 'returns nil user if there is no user in the environment' do
        expect(subject).to be_a User
        expect(subject).not_to be_persisted
        expect(subject.id).to be_nil
      end
    end

    context 'with a shibboleth user in the environment' do
      let(:user) do
        {
          username: 'some-user',
          patron_key: 'some-key',
          shibboleth: true,
          ldap_attributes: {
            'displayName' => 'Some User',
            'eduPersonEntitlement' => 'ldap:group1|ldap:group2',
            'suCardNumber' => '12345987654321'
          }.merge(ldap_attributes)
        }
      end

      let(:ldap_attributes) { {} }

      it 'returns a user when there is a user in the environment' do
        expect(subject).to be_a User
        expect(subject.sunetid).to eq 'some-user'
      end

      it 'returns the ldap groups as an array' do
        expect(subject.ldap_groups).to eq ['ldap:group1', 'ldap:group2']
      end

      it 'has the suCardNumber id from LDAP and translates it to the library_id' do
        expect(subject.library_id).to eq '987654321'
        expect(subject).not_to be_changed
      end

      describe 'email' do
        context 'with a mail attribute' do
          let(:ldap_attributes) { { 'mail' => 'the-email@fromldap.edu' } }

          it 'is the mail from ldap attributes' do
            expect(subject.email).to eq 'the-email@fromldap.edu'
          end
        end

        context 'without a mail attribute' do
          let(:ldap_attributes) { { 'suEmailStatus' => 'active' } }

          it 'is the "SUNet@stanford.edu" when there is no mail and the suEmailStatus is active' do
            expect(subject.email).to eq 'some-user@stanford.edu'
          end
        end
      end
    end
  end
end
