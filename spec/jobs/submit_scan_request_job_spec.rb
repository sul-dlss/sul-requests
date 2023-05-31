# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitScanRequestJob, type: :job do
  let(:folio_holding_response) do
    { 'instanceId' => 'f1c52ab3-721e-5234-9a00-1023e034e2e8',
      'source' => 'MARC',
      'modeOfIssuance' => 'single unit',
      'natureOfContent' => [],
      'holdings' => [],
      'items' =>
       [{ 'id' => '584baef9-ea2f-5ff5-9947-bbc348aee4a4',
          'notes' => [],
          'status' => 'Available',
          'barcode' => '3610512345678',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'callNumber' => { 'callNumber' => 'PR6123 .E475 W42 2009' },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'materialType' => 'book',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false },
        { 'id' => '99466f50-2b8c-51d4-8890-373190b8f6c4',
          'notes' => [],
          'status' => 'Available',
          'barcode' => '12345679',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'callNumber' => { 'callNumber' => 'PR6123 .E475 W42 2009' },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'materialType' => 'book',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false },
        { 'id' => 'deec4ae9-545c-5d60-85b0-b1048b9dad05',
          'notes' => [],
          'status' => 'Available',
          'barcode' => '36105028330483',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'callNumber' => { 'callNumber' => 'PR6123 .E475 W42 2009' },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'materialType' => 'book',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false }] }
  end

  before do
    allow_any_instance_of(FolioClient).to receive(:items_and_holdings).and_return(folio_holding_response)
    allow(Request.ils_job_class).to receive(:perform_later)
  end

  context 'when illiad response is success' do
    before do
      allow(IlliadRequest).to receive(:new).with(scan).and_return(illiad_request)
    end

    let(:scan) { create(:scan, :with_holdings) }
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
    end

    let(:user) { build(:scan_eligible_user) }
    let(:scan) { create(:scan, :without_validations, :with_item_title, user:) }
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
