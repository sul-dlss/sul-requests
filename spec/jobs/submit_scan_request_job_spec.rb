# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitScanRequestJob, type: :job do
  context 'when illiad response is success' do
    before do
      allow(IlliadRequest).to receive(:new).with(scan).and_return(illiad_request)
      allow(Request.ils_job_class).to receive(:perform_later)
    end

    let(:scan) { create(:scan, :with_holdings) }
    let(:illiad_request) { instance_double(IlliadRequest, request!: double(body: { 'IlliadResponse' => 'Blah' }.to_json)) }

    context 'when the scan destination is present' do
      it 'makes a request to illiad and the ILS' do
        described_class.perform_now(scan)

        expect(illiad_request).to have_received(:request!)

        expect(scan.illiad_response_data).to eq({ 'IlliadResponse' => 'Blah' })
        expect(Request.ils_job_class).to have_received(:perform_later).with(scan.id, anything)
      end
    end

    context 'when the scan_destination is not present' do
      let(:scan) { create(:scan, :without_validations, origin: 'SAL3') }

      # SAL3 scans should not be sent to the ILS
      it 'makes a request to illiad, but not to the ILS' do
        described_class.perform_now(scan)

        expect(illiad_request).to have_received(:request!)

        expect(scan.illiad_response_data).to eq({ 'IlliadResponse' => 'Blah' })
        expect(Request.ils_job_class).not_to have_received(:perform_later).with(scan.id, anything)
      end
    end
  end

  context 'when illiad response is an error' do
    before do
      allow(IlliadRequest).to receive(:new).with(scan).and_return(failed_illiad_request)
      allow(Request.ils_job_class).to receive(:perform_later)
    end

    let(:user) { build(:scan_eligible_user) }
    let(:scan) { create(:scan, :without_validations, user:) }
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
