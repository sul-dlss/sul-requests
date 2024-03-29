# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediatedPage do
  let(:user) { create(:sso_user) }

  before do
    allow_any_instance_of(PagingSchedule::Scheduler).to receive(:valid?).with(anything).and_return(true)
    allow(Settings.ils.bib_model.constantize).to receive(:fetch)
  end

  it 'has the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'MediatedPage'
  end

  describe 'validation' do
    it 'does not allow non-mediated pages to be created' do
      expect do
        described_class.create!(item_id: '1234',
                                origin: 'GREEN',
                                origin_location: 'GRE-STACKS',
                                destination: 'ART',
                                needed_date: Time.zone.today + 1.day)
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: This item is not mediatable')
    end

    it 'does not not allow pages to be created with destinations that are not valid pickup libraries of their origin' do
      expect do
        described_class.create!(item_id: '1234',
                                barcodes: ['12345678'],
                                origin: 'ART',
                                origin_location: 'ART-LOCKED-LARGE',
                                destination: 'GREEN',
                                needed_date: Time.zone.today + 1.day,
                                bib_data: build(:single_mediated_holding))
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Destination is not a valid pickup library')
    end

    it 'does not allow requests to be submitted without a needed_date when required' do
      expect do
        described_class.create!(item_id: '1234',
                                barcodes: ['12345678'],
                                origin: 'ART',
                                origin_location: 'ART-LOCKED-LARGE',
                                destination: 'ART',
                                bib_data: build(:single_mediated_holding))
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: I plan to visit on can't be blank")
    end

    it 'allows requests to be submitted without a needed_date when not required' do
      expect do
        described_class.create!(item_id: '1234',
                                origin: 'SAL3',
                                origin_location: 'SAL3-PAGE-MP',
                                user:,
                                destination: 'EARTH-SCI',
                                item_title: 'foo',
                                bib_data: build(:page_mp_holdings))
      end.not_to raise_error
    end
  end

  describe 'scopes' do
    before do
      build(
        :mediated_page,
        approval_status: :approved,
        user:,
        needed_date: Time.zone.today - 3.days
      ).save(validate: false)

      build(
        :mediated_page,
        approval_status: :approved,
        user:,
        needed_date: Time.zone.today - 2.days
      ).save(validate: false)

      build(
        :mediated_page,
        approval_status: :marked_as_done,
        user:,
        needed_date: Time.zone.today - 1.day
      ).save(validate: false)

      create(:page_mp_mediated_page, user:, needed_date: Time.zone.today)
      create(:page_mp_mediated_page, user:, needed_date: Time.zone.today + 1.day)
    end

    describe 'archived' do
      it 'returns records whose needed_date is older than today' do
        expect(described_class.archived.length).to eq 3
      end

      it 'returns records in descending needed date order' do
        expect(described_class.archived[0].needed_date).to eq Time.zone.today - 1.day
        expect(described_class.archived[1].needed_date).to eq Time.zone.today - 2.days
        expect(described_class.archived[2].needed_date).to eq Time.zone.today - 3.days
      end
    end

    describe 'completed' do
      it 'returns the requests with an approval status of anything other than unnaproved' do
        expect(described_class.completed.count).to eq 3
      end

      it 'returns records in descending needed date order' do
        expect(described_class.completed[0].needed_date).to eq Time.zone.today - 1.day
        expect(described_class.completed[1].needed_date).to eq Time.zone.today - 2.days
        expect(described_class.completed[2].needed_date).to eq Time.zone.today - 3.days
      end
    end

    describe 'for_origin' do
      it 'returns the records for a given origin' do
        expect(described_class.for_origin('ART').length).to eq 3
        expect(described_class.for_origin('SAL3-PAGE-MP').length).to eq 2
      end
    end
  end

  describe 'all_approved?' do
    let(:subject) { build(:mediated_page_with_holdings, user:) }

    before do
      stub_symphony_response(build(:symphony_page_with_multiple_items))
      subject.barcodes = ['12345678', '23456789']
      allow(Request.ils_job_class).to receive(:perform_now)
    end

    it 'returns true when all requested barcodes are approved' do
      subject.item_status('12345678').approve!('jstanford')
      subject.item_status('23456789').approve!('jstanford')
      expect(subject).to be_all_approved
    end

    it 'returns false when not all the requested barcodes are approved' do
      subject.item_status('12345678').approve!('jstanford')
      expect(subject).not_to be_all_approved
    end
  end

  describe '#item_statuses' do
    let(:subject) { build(:mediated_page_with_holdings, user:) }

    before do
      stub_symphony_response(build(:symphony_page_with_multiple_items))
      subject.barcodes = ['12345678', '23456789']
    end

    it 'returns an enumerable of the statuses' do
      expect(subject.item_statuses.count).to eq 2
      expect(subject.item_statuses.map(&:id)).to eq ['12345678', '23456789']
    end
  end

  describe 'TokenEncryptable' do
    it 'mixins TokenEncryptable' do
      expect(subject).to be_kind_of TokenEncryptable
    end

    it 'adds the user email address to the token' do
      subject.user = build(:non_sso_user)
      expect(subject.to_token(version: 1)).to match(/jstanford@stanford.edu$/)
    end
  end

  describe 'requestable' do
    it { is_expected.to be_requestable_with_name_email }
    it { is_expected.to be_requestable_with_library_id }
  end

  describe '#requires_needed_date?' do
    it 'is false when the origin location is PAGE-MP' do
      subject.origin_location = 'PAGE-MP'
      expect(subject).not_to be_requires_needed_date
    end

    it 'is false when the origin location is SAL3-PAGE-MP' do
      subject.origin_location = 'SAL3-PAGE-MP'
      expect(subject).not_to be_requires_needed_date
    end

    it 'is true when otherwise' do
      expect(subject).to be_requires_needed_date
    end
  end

  describe '#submit!' do
    it 'does not immediately submit the request to Symphony' do
      expect(Request.ils_job_class).not_to receive(:perform_now)
      subject.submit!
    end

    describe 'for library id users' do
      let!(:subject) { create(:mediated_page) }

      it 'sends a mediator email, but does not send a confirmation email' do
        subject.user = create(:library_id_user)
        expect do
          expect(subject.submit!).to be true
        end.to have_enqueued_mail
      end
    end

    describe 'for everybody else' do
      let!(:subject) { create(:mediated_page) }

      it 'sends a confirmation email and a mediator email' do
        expect do
          expect(subject.submit!).to be true
        end.to have_enqueued_mail.twice
      end
    end
  end

  describe 'send_approval_status!' do
    let!(:subject) { create(:mediated_page) }

    it 'returns true' do
      expect do
        subject.send_approval_status!
      end.not_to have_enqueued_mail
      expect(subject.send_approval_status!).to be true
    end
  end

  describe '#mediator_notification_email_address' do
    it 'fetches email addresses for origin libraires' do
      subject.origin = 'SPEC-COLL'
      expect(
        subject.mediator_notification_email_address
      ).to eq SULRequests::Application.config.mediator_contact_info['SPEC-COLL'][:email]
    end

    it 'fetches email addresses for origin locations' do
      subject.origin_location = 'SAL3-PAGE-MP'
      expect(
        subject.mediator_notification_email_address
      ).to eq SULRequests::Application.config.mediator_contact_info['SAL3-PAGE-MP'][:email]
    end
  end

  describe '#mark_all_archived_as_complete' do
    let!(:mediated_page) { create(:mediated_page) }

    before do
      mediated_page.needed_date = 5.days.ago
      mediated_page.save(validate: false)
      stub_bib_data_json(build(:single_mediated_holding))
    end

    context 'requests that have all of their items approved' do
      before do
        expect_any_instance_of(described_class).to receive(:all_approved?).at_least(:once).and_return(true)
      end

      it 'are marked as approved' do
        expect(mediated_page).not_to be_approved

        described_class.mark_all_archived_as_complete!

        expect(mediated_page.reload).to be_approved
      end
    end

    context 'requests that do not have all their items approved' do
      before do
        expect_any_instance_of(described_class).to receive(:all_approved?).at_least(:once).and_return(false)
      end

      it 'are marked as done' do
        expect(mediated_page).not_to be_marked_as_done

        described_class.mark_all_archived_as_complete!

        expect(mediated_page.reload).to be_marked_as_done
      end
    end
  end

  describe '#needed_dates_for_origin_after_date' do
    before do
      build(:mediated_page, origin: 'ART', needed_date: Time.zone.today - 2.days).save(validate: false)
      build(:mediated_page, origin: 'ART', needed_date: Time.zone.today - 1.day).save(validate: false)
      build(:mediated_page, origin: 'ART', needed_date: Time.zone.today).save(validate: false)
      build(:mediated_page, origin: 'ART', needed_date: Time.zone.today + 2.days).save(validate: false)
      build(:mediated_page, origin: 'ART', needed_date: Time.zone.today + 1.day).save(validate: false)
      build(:mediated_page, origin: 'ART', needed_date: Time.zone.today + 1.day).save(validate: false)
      build(:mediated_page, origin: 'EDUCATION', needed_date: Time.zone.today + 3.days).save(validate: false)
    end

    let(:dates) { described_class.needed_dates_for_origin_after_date(origin: 'ART', date: Time.zone.today) }

    it "returns request's needed_dates that are after today" do
      expect(dates.length).to eq 2
    end

    it 'does not duplicate dates' do
      expect(dates.length).to eq dates.uniq.length
    end

    it 'sorts the dates' do
      expect(dates).to eq(
        [
          Time.zone.today + 1.day,
          Time.zone.today + 2.days
        ]
      )
    end

    it 'does not include requests from other origins' do
      expect(
        dates.any? do |date|
          date == Time.zone.today + 3.days # EDUCATION needed_date
        end
      ).to be false
    end
  end
end
