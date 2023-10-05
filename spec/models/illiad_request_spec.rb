# frozen_string_literal: true

require 'rails_helper'

# A fake Request type that can be sent to ILLiad
class ExampleRequest < Request
  def illiad_request_params
    {}
  end
end

RSpec.describe IlliadRequest do
  subject { described_class.new(request) }

  let(:user) { create(:sso_user) }
  let(:request) { ExampleRequest.new(user:) }

  before do
    allow(Settings).to receive(:sul_illiad).and_return('https://illiad.stanford.edu')
    allow(Settings).to receive(:illiad_api_key).and_return('some-api-key')
    stub_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
    subject.request!
  end

  it 'POSTs to the illiad api url' do
    expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')).to have_been_made
  end

  describe 'request headers' do
    it 'declares that it is sending JSON' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(headers: { 'Content-Type' => 'application/json' })).to have_been_made
    end

    it 'asks for a JSON response' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(headers: { 'Accept' => 'application/json; version=1' })).to have_been_made
    end

    it 'includes the api key' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(headers: { 'ApiKey' => 'some-api-key' })).to have_been_made
    end
  end

  describe 'request body' do
    it 'includes the user sunetid' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: /"Username":"some-sso-user"/)).to have_been_made
    end

    it 'includes the process type' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: /"ProcessType":"Borrowing"/)).to have_been_made
    end
  end

  context 'with a scan' do
    subject { described_class.new(scan) }

    let(:scan) { create(:scan, :with_holdings_barcodes, user:) }

    describe 'request body' do
      it 'includes the request type' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"RequestType":"Article"/)).to have_been_made
      end

      it 'includes the instructions' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"SpecIns":"Scan and Deliver Request"/)).to have_been_made
      end

      it 'includes the title' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"PhotoJournalTitle":"SAL Item Title"/)).to have_been_made
      end

      it 'includes the section title' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"PhotoArticleTitle":"Section Title for Scan 12345"/)).to have_been_made
      end

      it 'includes the author' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"PhotoArticleAuthor":"John Q. Public"/)).to have_been_made
      end

      it 'includes the first item call number' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"CallNumber":"ABC 123"/)).to have_been_made
      end

      it 'includes the first item barcode as the ILL number' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"ILLNumber":"12345678"/)).to have_been_made
      end

      it 'includes the first item barcode as the item number' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"ItemNumber":"12345678"/)).to have_been_made
      end

      it 'includes the requested page range' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"PhotoJournalInclusivePages":"1-10"/)).to have_been_made
      end

      it 'includes the library' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"Location":"SAL3"/)).to have_been_made
      end

      it 'includes the location' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"ReferenceNumber":"STACKS"/)).to have_been_made
      end
    end
  end

  context 'with a hold/recall' do
    subject { described_class.new(hold) }

    let(:hold) { create(:hold_recall, :with_holdings_barcodes, user:) }

    describe 'request body' do
      it 'includes the request type'
      it 'includes the instructions'
      it 'includes the title'
      it 'includes the author'
      it 'includes the ISBN'
      it 'includes the volume'
      it 'includes the publisher'
      it 'includes the place of publication'
      it 'includes the date of publication'
      it 'includes the edition'
      it 'includes the OCLC number'
      it 'includes the catalog view link'
      it 'includes the not needed after date'
    end
  end
end
