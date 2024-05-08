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
end
