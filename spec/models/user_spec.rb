require 'rails_helper'

describe User do
  describe 'validations' do
    it 'should only allow unique webauth ids' do
      User.create!(webauth: 'some-user')
      expect(
        -> { User.create!(webauth: 'some-user') }
      ).to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#sucard_number=' do
    it 'sets the library_id omitings the first 5 digits' do
      expect(subject.library_id).to be_blank
      subject.sucard_number = '12345987654321'
      expect(subject.library_id).to eq '987654321'
    end
  end

  describe '#library_id' do
    it 'upcases the library id to match symphony' do
      subject.library_id = 'somelibid'
      expect(subject.library_id).to eq 'SOMELIBID'
    end
  end

  describe '#email_address' do
    describe 'for webauth users' do
      before do
        subject.webauth = 'jstanford'
      end
      it 'returns the email address set by the email attribute' do
        subject.email = 'jjstanford@stanford.edu'
        expect(subject.email_address).to eq 'jjstanford@stanford.edu'
      end

      context 'when there is no email set from the LDAP attributes' do
        it 'sets the value to the SUNet@stanford.edu' do
          expect(subject.email_address).to eq 'jstanford@stanford.edu'
        end

        it 'Notifies the exception handling service' do
          expect(Honeybadger).to receive(:notify).with(
            'Webauth user record being created without a valid email address. Using jstanford@stanford.edu instead.'
          )
          expect(subject.email_address).to eq 'jstanford@stanford.edu'
        end
      end
    end

    describe 'for non-webauth users' do
      it 'returns the user email address' do
        subject.name = 'Jane Stanford'
        subject.email = 'jstanford@example.com'
        expect(subject.email_address).to eq 'jstanford@example.com'
      end
    end

    describe 'for library ID users' do
      it 'is blank' do
        subject.library_id = '123456'
        expect(subject.email_address).to be_blank
      end
    end
  end

  describe '#to_email_string' do
    describe 'for webauth users' do
      it 'should be their Stanford email address' do
        subject.name = 'Jane Stanford'
        subject.webauth = 'jstanford'
        subject.email = 'jstanford@stanford.edu'
        expect(subject.to_email_string).to eq 'Jane Stanford (jstanford@stanford.edu)'
      end
    end

    describe 'for non-webauth users' do
      it 'should be their name plus their email in parenthesis' do
        subject.name = 'Jane Stanford'
        subject.email = 'jstanford@stanford.edu'
        expect(subject.to_email_string).to eq 'Jane Stanford (jstanford@stanford.edu)'
      end
    end

    describe 'for users without a name' do
      it 'should just be their email address' do
        subject.webauth = 'jstanford'
        subject.email = 'jstanford@stanford.edu'
        expect(subject.to_email_string).to eq 'jstanford@stanford.edu'
      end
    end

    describe 'for library id users' do
      it 'is blank' do
        subject.library_id = '123456'
        expect(subject.to_email_string).to be_blank
      end
    end
  end
  describe '#webauth_user?' do
    it 'should return false when the user has no WebAuth attribute' do
      expect(subject).to_not be_webauth_user
    end
    it 'should return true when the user has a WebAuth attribute' do
      subject.webauth = 'WebAuth User'
      expect(subject).to be_webauth_user
    end
  end
  describe '#non_webauth_user?' do
    describe 'with name and email' do
      before do
        subject.name = 'Jane Stanford'
        subject.email = 'jstanford@stanford.edu'
      end
      it 'should return true when the user has a name and email address but not a webauth ID' do
        expect(subject).to be_non_webauth_user
      end
      it 'should return false when the user has a webauth ID' do
        subject.webauth = 'jstanford'
        expect(subject).to_not be_non_webauth_user
      end
    end
  end
  describe '#library_id_user?' do
    it 'is true when the user has supplied a library ID' do
      subject.library_id = '12345'
      expect(subject).to be_library_id_user
    end
    it 'is false when the user has a webauth ID' do
      subject.webauth = 'jstanford'
      subject.library_id = '12345'
      expect(subject).not_to be_library_id_user
    end
  end
  describe '#super_admin?' do
    it 'should return false when the user is not a super admin' do
      expect(subject).to_not be_super_admin
    end
    it 'should return true when the user is in a superadmin group' do
      allow(subject).to receive_messages(ldap_groups: ['FAKE-TEST-SUPER-ADMIN-GROUP'])
      expect(subject).to be_super_admin
    end
  end
  describe '#site_admin?' do
    it 'should return false when the user is not a site admin' do
      expect(subject).to_not be_site_admin
    end
    it 'should return true when the user is in a site admin group' do
      allow(subject).to receive_messages(ldap_groups: ['FAKE-TEST-SITE-ADMIN-GROUP'])
      expect(subject).to be_site_admin
    end
  end
  describe '#admin_for_origin?' do
    it 'should return false when the user is not in an originating library admin group' do
      expect(subject).to_not be_admin_for_origin('FAKE-ORIGIN-LIBRARY')
    end
    it 'should return true when the user is in a site admin group' do
      allow(subject).to receive_messages(ldap_groups: ['FAKE-ORIGIN-LIBRARY-TEST-LDAP-GROUP'])
      expect(subject).to be_admin_for_origin('FAKE-ORIGIN-LIBRARY')
    end

    it 'should return true when the user is an admin of a location' do
      allow(subject).to receive_messages(ldap_groups: ['FAKE-ORIGIN-LOCATION-TEST-LDAP-GROUP'])
      expect(subject).to be_admin_for_origin('FAKE-ORIGIN-LOCATION')
    end
  end

  describe '#proxy_access' do
    it 'checks if the user has proxy access' do
      subject.library_id = '12345'
      expect(subject.proxy_access.libid).to eq '12345'
    end
  end
end
