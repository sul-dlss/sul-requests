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
  describe '#to_email_string' do
    describe 'for webauth users' do
      it 'should be their Stanford email address' do
        subject.webauth = 'jstanford'
        expect(subject.to_email_string).to eq 'jstanford@stanford.edu'
      end
    end
    describe 'for non-webauth users' do
      it 'should be their name plus their email in parenthesis' do
        subject.name = 'Jane Stanford'
        subject.email = 'jstanford@stanford.edu'
        expect(subject.to_email_string).to eq 'Jane Stanford (jstanford@stanford.edu)'
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
  describe '#superadmin?' do
    it 'should return false when the user is not a super admin' do
      expect(subject).to_not be_superadmin
    end
    it 'should return true when the user is in a superadmin group' do
      allow(subject).to receive_messages(ldap_groups: ['FAKE-TEST-SUPER-ADMIN-GROUP'])
      expect(subject).to be_superadmin
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
  end
end
