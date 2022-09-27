# frozen_string_literal: true

require 'rails_helper'

describe PicklistMailer do
  describe '.deliver_picklist' do
    let(:state_file) do
      Tempfile.new('foo').tap do |t|
        t.write(last_run_time)
        t.rewind
        t.close
      end
    end
    let(:last_run_time) { Time.zone.parse('2020-08-01T00:00:00Z') }
    let(:now) { Time.zone.parse('2020-08-15T00:00:00Z') }

    before do
      allow(Time.zone).to receive(:now).and_return(now)
      allow(described_class).to receive(:picklist_notification).and_return(double(deliver_now: true))
    end

    it 'sends a picklist since the last time it was run' do
      described_class.deliver_picklist('ART', last_run_file: state_file.path)

      expect(described_class).to have_received(:picklist_notification).with('ART', range: last_run_time...now)
    end

    it 'defaults to the last day' do
      described_class.deliver_picklist('ART', last_run_file: Tempfile.new('whatever').path)

      expect(described_class).to have_received(:picklist_notification).with('ART', range: (now - 1.day)...now)
    end

    it 'records its last run time' do
      described_class.deliver_picklist('ART', last_run_file: state_file.path)

      expect(File.read(state_file.path)).to eq now.to_s
    end
  end

  describe '#picklist_notification' do
    let(:user) { create(:superadmin_user) }
    let(:mock_client) do
      instance_double(SymphonyClient, login_by_library_id: nil, bib_info: {}, catalog_info: {}, patron_info: {})
    end

    before do
      allow(SymphonyClient).to receive(:new).and_return(mock_client)
      allow(SubmitSymphonyRequestJob).to receive(:perform_now)

      create(:mediated_page_with_holdings, user: create(:non_sso_user), barcodes: %w(12345678 23456789))
      b = create(:mediated_page_with_holdings, user: create(:non_sso_user), barcodes: %w(12345678 23456789))
      b.item_statuses.to_a.first.approve!(user, Time.zone.now - 5.days)
      b.item_statuses.to_a.last.approve!(user, Time.zone.now - 1.day)
      c = create(:mediated_page_with_holdings, user: create(:non_sso_user), barcodes: %w(12345678 23456789))
      c.item_statuses.first.approve!(user, Time.zone.now - 1.day)
    end

    it 'attaches a picklist' do
      skip 'SPEC-COLL is using Aeon now'
      mail = described_class.picklist_notification('SPEC-COLL', range: (Time.zone.now - 2.days)...Time.zone.now)

      expect(mail.to).to include 'specialcollections@stanford.edu'
      expect(mail.attachments.length).to eq 1

      body = Capybara.HTML(mail.attachments.first.decode_body)

      expect(body).to have_css '.page', count: 2
      expect(body).to have_content '23456789'
      expect(body).to have_content '12345678'
    end
  end
end
