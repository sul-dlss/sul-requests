# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitFolioRequestJob do
  let(:user) { create(:sequence_sso_user) }
  let(:patron) { instance_double(Folio::Patron, id: 3) }
  let(:client) { instance_double(FolioClient, get_item: { 'id' => 4 }, get_service_point: { 'id' => 5 }, create_item_hold: double) }
  let(:expected_date) { DateTime.now.beginning_of_day.utc.iso8601 }

  before do
    allow(Request).to receive(:find).and_return(request)
    allow(request.user).to receive(:patron).and_return(patron)
    allow(FolioClient).to receive(:new).and_return(client)
  end

  context 'with a HoldRecall type request' do
    let(:request) { create(:hold_recall_with_holdings, barcodes: ['12345678'], user:) }

    it 'calls the create_item_hold API method' do
      described_class.perform_now(request.id)
      expect(client).to have_received(:create_item_hold).with(3, 4, FolioClient::HoldRequest)
    end
  end
end
