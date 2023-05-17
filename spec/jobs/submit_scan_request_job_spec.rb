# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitScanRequestJob, type: :job do
  context 'when illiad response is success' do
    before do
      allow(IlliadRequest).to receive(:new).with(scan).and_return(illiad_request)
      allow(Request.ils_job_class).to receive(:perform_later)
    end

    let(:scan) { create(:scan) }
    let(:illiad_request) { instance_double(IlliadRequest, request!: double(body: { 'IlliadResponse' => 'Blah' }.to_json)) }

    it 'makes a request to illiad' do
      described_class.perform_now(scan)

      expect(illiad_request).to have_received(:request!)

      expect(scan.illiad_response_data).to eq({ 'IlliadResponse' => 'Blah' })
    end

    it 'enqueues a request to the ILS' do
      described_class.perform_now(scan)

      expect(Request.ils_job_class).to have_received(:perform_later).with(scan.id, anything)
    end
  end

  context 'when illiad response is an error' do
    before do
      allow(IlliadRequest).to receive(:new).with(scan).and_return(failed_illiad_request)
      allow(Request.ils_job_class).to receive(:perform_later)
    end

    let(:user) { build(:scan_eligible_user) }
    let(:scan) { create(:scan, user: user) }
    let(:failed_illiad_request) do
      instance_double(IlliadRequest, request!: double(body: { 'Message' => 'error' }.to_json))
    end

    it 'redirects to the sorry page if the illiad request fails' do
      described_class.perform_now(scan)

      expect(failed_illiad_request).to have_received(:request!)

      expect(scan.illiad_response_data).to eq({ 'Message' => 'error' })
    end
  end
end
