require 'rails_helper'

describe MediatedPage do
  it 'should have the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'MediatedPage'
  end

  describe 'validation' do
    it 'should not allow non-mediated pages to be created' do
      expect do
        MediatedPage.create!(item_id: '1234',
                             origin: 'GREEN',
                             origin_location: 'STACKS',
                             destination: 'BIOLOGY',
                             needed_date: Time.zone.today + 1.day)
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: This item is not mediatable')
    end

    it 'does not not allow pages to be created with destinations that are not valid pickup libraries of their origin' do
      expect do
        MediatedPage.create!(item_id: '1234',
                             origin: 'SPEC-COLL',
                             origin_location: 'STACKS',
                             destination: 'GREEN',
                             needed_date: Time.zone.today + 1.day)
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Destination is not a valid pickup library')
    end
  end

  describe 'scopes' do
    before do
      build(:mediated_page, needed_date: Time.zone.today - 3.days).save(validate: false)
      build(:mediated_page, needed_date: Time.zone.today - 2.days).save(validate: false)
      build(:mediated_page, needed_date: Time.zone.today - 1.day).save(validate: false)
      create(:hoover_mediated_page, needed_date: Time.zone.today)
      create(:hoover_mediated_page, needed_date: Time.zone.today + 1.day)
    end
    describe 'archived' do
      it 'returns records whose needed_date is older than today' do
        expect(MediatedPage.archived.length).to eq 3
      end
    end

    describe 'active' do
      it 'reutrns the records whose needed_date is today or a future date' do
        expect(MediatedPage.active.length).to eq 2
      end
    end

    describe 'for_origin' do
      it 'returns the records for a given origin' do
        expect(MediatedPage.for_origin('SPEC-COLL').length).to eq 3
        expect(MediatedPage.for_origin('HOOVER').length).to eq 2
      end
    end
  end

  describe '#ad_hoc_item_commentable?' do
    it 'is true when the library is SPEC-COLL' do
      subject.origin = 'SPEC-COLL'
      expect(subject).to be_ad_hoc_item_commentable
    end

    it 'is false when the library is not SPEC-COLL' do
      expect(subject).not_to be_ad_hoc_item_commentable
    end
  end

  describe '#request_commentable?' do
    it 'is true when the library is SPEC-COLL' do
      subject.origin = 'SPEC-COLL'
      expect(subject).to be_request_commentable
    end
    it 'is false when the library is not SPEC-COLL' do
      subject.origin = 'HOOVER'
      expect(subject).to_not be_request_commentable
    end
  end

  describe 'item_commentable?' do
    it 'is false' do
      expect(subject).not_to be_item_commentable
    end
  end

  describe 'TokenEncryptable' do
    it 'should mixin TokenEncryptable' do
      expect(subject).to be_kind_of TokenEncryptable
    end
    it 'should add the user email address to the token' do
      subject.user = build(:non_webauth_user)
      expect(subject.to_token).to match(/jstanford@stanford.edu$/)
    end
  end

  describe 'requestable' do
    it { is_expected.to be_requestable_by_all }
    it { is_expected.to be_requestable_with_library_id }
    it { is_expected.not_to be_requestable_with_sunet_only }

    describe 'for hopkins' do
      before { subject.origin = 'HOPKINS' }
      it { is_expected.not_to be_requestable_by_all }
      it { is_expected.not_to be_requestable_with_library_id }
      it { is_expected.to be_requestable_with_sunet_only }
    end
  end

  describe '#item_limit' do
    it 'should be nil for normal libraries' do
      expect(subject.item_limit).to be_nil
    end

    it 'should be 5 for items from SPEC-COLL' do
      subject.origin = 'SPEC-COLL'
      expect(subject.item_limit).to eq 5
    end
  end

  describe '#requires_needed_date?' do
    it 'is false when the library is HOPKINS' do
      subject.origin = 'HOPKINS'
      expect(subject.requires_needed_date?).to be_falsey
    end

    it 'is false when the origin location is PAGE-MP' do
      subject.origin_location = 'PAGE-MP'
      expect(subject.requires_needed_date?).to be_falsey
    end

    it 'is true when otherwise' do
      expect(subject.requires_needed_date?).to be_truthy
    end
  end

  describe '#submit!' do
    it 'does not submit the request to Symphony' do
      expect(SubmitSymphonyRequestJob).not_to receive(:perform_now)
      subject.submit!
    end
  end
end
