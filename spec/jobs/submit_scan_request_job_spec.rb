# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitScanRequestJob, type: :job do
  before do
    allow(IlliadRequest).to receive(:new).with(scan).and_return(illiad_request)
    allow(SubmitSymphonyRequestJob).to receive(:perform_later)
  end

  let(:scan) { create(:scan) }
  let(:illiad_request) { instance_double(IlliadRequest, request!: double(body: { 'IlliadResponse' => 'Blah' }.to_json)) }

  it 'makes a request to illiad' do
    described_class.perform_now(scan)

    expect(illiad_request).to have_received(:request!)

    expect(scan.illiad_response_data).to eq({ 'IlliadResponse' => 'Blah' })
  end

  it 'enqueues a request to symphony' do
    described_class.perform_now(scan)

    expect(SubmitSymphonyRequestJob).to have_received(:perform_later).with(scan.id, anything)
  end
end
