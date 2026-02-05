# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  describe 'validations' do
    it 'onlies allow unique sunetids' do
      described_class.create!(sunetid: 'some-user')
      expect do
        described_class.create!(sunetid: 'some-user')
      end.to raise_error(ActiveRecord::RecordInvalid)
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

  describe '#barcode' do
    it 'uses the library id' do
      subject.library_id = 'somelibid'
      expect(subject.barcode).to eq 'SOMELIBID'
    end

    context 'returns the library id from FOLIO' do
      let(:patron) { instance_double(Folio::Patron, library_id: '123456789') }

      it 'uses the patron barcode from the ILS' do
        allow(Folio::Patron).to receive(:find_by).and_return(patron)
        subject.library_id = 'somelibid'

        expect(subject.barcode).to eq '123456789'
      end
    end
  end

  describe '#email_address' do
    describe 'for SSO users' do
      before do
        subject.sunetid = 'jstanford'
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
          allow(Honeybadger).to receive(:notify)
          expect(subject.email_address).to eq 'jstanford@stanford.edu'

          expect(Honeybadger).to have_received(:notify).with(
            'SSO User being created without an email address. Using jstanford@stanford.edu instead.'
          )
        end
      end
    end

    describe 'for non-SSO users' do
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
    describe 'for SSO users' do
      it 'is their Stanford email address' do
        subject.name = 'Jane Stanford'
        subject.sunetid = 'jstanford'
        subject.email = 'jstanford@stanford.edu'
        expect(subject.to_email_string).to eq 'Jane Stanford (jstanford@stanford.edu)'
      end
    end

    describe 'for non-SSO users' do
      it 'is their name plus their email in parenthesis' do
        subject.name = 'Jane Stanford'
        subject.email = 'jstanford@stanford.edu'
        expect(subject.to_email_string).to eq 'Jane Stanford (jstanford@stanford.edu)'
      end
    end

    describe 'for users without a name' do
      it 'justs be their email address' do
        subject.sunetid = 'jstanford'
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

  describe '#sso_user?' do
    it 'returns false when the user has no sunetid attribute' do
      expect(subject).not_to be_sso_user
    end

    it 'returns true when the user has a sunetid attribute' do
      subject.sunetid = 'SSO user'
      expect(subject).to be_sso_user
    end
  end

  describe '#student_type' do
    it 'processes the data from the database properly' do
      expect(subject.student_type).to eq([])

      subject.student_type = 'type1;type2'
      expect(subject).to be_changed
      subject.save
      expect(subject.student_type).to eq %w[type1 type2]
    end
  end

  describe '#library_id_user?' do
    it 'is true when the user has supplied a library ID' do
      subject.library_id = '12345'
      expect(subject).to be_library_id_user
    end

    it 'is false when the user has not supplied a library ID' do
      expect(subject).not_to be_library_id_user
    end
  end

  describe '#name_email_user?' do
    it 'is true when the user has supplied a name and email address' do
      subject.name = 'jstanford'
      subject.email = 'jstanford@stanford.edu'
      expect(subject).to be_name_email_user
    end

    it 'is false when the user has not supplied a library ID' do
      expect(subject).not_to be_name_email_user
    end
  end

  describe '#super_admin?' do
    it 'returns false when the user is not a super admin' do
      expect(subject).not_to be_super_admin
    end

    it 'returns true when the user is in a superadmin group' do
      allow(subject).to receive_messages(ldap_groups: ['sul:requests-super-admin'])
      expect(subject).to be_super_admin
    end
  end

  describe '#site_admin?' do
    it 'returns false when the user is not a site admin' do
      expect(subject).not_to be_site_admin
    end

    it 'returns true when the user is in a site admin group' do
      allow(subject).to receive_messages(ldap_groups: ['sul:requests-site-admin'])
      expect(subject).to be_site_admin
    end
  end

  describe '#patron' do
    before do
      subject.name = 'jstanford'
      subject.email = 'jstanford@stanford.edu'
    end

    it 'returns placeholder patron for name email user' do
      expect(subject.patron).to have_attributes(id: nil, display_name: 'jstanford', email: 'jstanford@stanford.edu', block_reasons: [])
    end
  end
end
