# frozen_string_literal: true

require 'rails_helper'

# A fake Request type that can be sent to ILLiad
class ExampleRequest < Request
  include Illiadable
end

RSpec.describe SubmitIlliadRequestJob do
  subject { described_class.new(request_id) }

  let(:request_id) { 1 }
  let(:request) { instance_double(ExampleRequest, illiad_request_params: { a: 1 }) }
  let(:illiad_request) { instance_double(IlliadRequest, request!: illiad_response) }
  let(:illiad_response) { instance_double(Faraday::Response, body: '{"Foo": "Bar"}', success?: true) }

  before do
    allow(Request).to receive(:find).with(request_id).and_return(request)
    allow(IlliadRequest).to receive(:new).with({ a: 1 }).and_return(illiad_request)
    allow(request).to receive(:update)
    allow(request).to receive(:illiad_error?).and_return(false)
  end

  it 'submits the request to illiad' do
    subject.perform(request_id)
    expect(illiad_request).to have_received(:request!)
  end

  it 'stores the response data from illiad on the request' do
    subject.perform(request_id)
    expect(request).to have_received(:update).with(illiad_response_data: { 'Foo' => 'Bar' })
  end

  context 'when the request to illiad failed' do
    let(:illiad_response) { instance_double(Faraday::Response, success?: false) }

    before do
      allow(request).to receive(:notify_ilb!)
    end

    it 'notifies staff' do
      subject.perform(request_id)
      expect(request).to have_received(:notify_ilb!)
    end
  end

  context 'when illiad response data contains an error' do
    before do
      allow(request).to receive(:illiad_error?).and_return(true)
      allow(request).to receive(:notify_ilb!)
    end

    it 'notifies staff' do
      subject.perform(request_id)
      expect(request).to have_received(:notify_ilb!)
    end
  end
end
