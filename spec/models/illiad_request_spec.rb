# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IlliadRequest do
  subject { described_class.new(request) }

  let(:user) { create(:sso_user) }
  let(:patron) { instance_double(Folio::Patron, blocked?: false) }
  let(:request) { create(:scan, :with_holdings_barcodes, user:) }

  before do
    allow(request).to receive(:user).and_return(user)
    allow(user).to receive(:patron).and_return(patron)
    allow(Settings).to receive_messages(sul_illiad: 'https://illiad.stanford.edu', illiad_api_key: 'some-api-key')
    stub_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
    subject.request!
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

  context 'with a scan' do
    let(:request) { create(:scan, :with_holdings_barcodes, user:) }

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
        .with(body: /"ReferenceNumber":"SAL3-STACKS"/)).to have_been_made
      end

      it 'includes the barcode again as the ILL number' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"ILLNumber":"12345678"/)).to have_been_made
      end
    end
  end

  context 'with a hold/recall' do
    let(:request) { create(:hold_recall_checkedout) }

    describe 'request body' do
      it 'includes the request type' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"RequestType":"Loan"/)).to have_been_made
      end

      it 'includes the instructions' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: %r{"SpecIns":"Hold/Recall Request"})).to have_been_made
      end

      it 'includes the title' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"LoanTitle":"Checked out item"/)).to have_been_made
      end

      it 'includes the author' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"LoanAuthor":"John Q. Public"/)).to have_been_made
      end

      it 'includes the not needed after date' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"NotWantedAfter":"#{Time.zone.today.strftime('%Y-%m-%d')}"/)).to have_been_made
      end

      it 'includes the pickup location' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"ItemInfo4":"GREEN"/)).to have_been_made
      end
    end
  end
end
