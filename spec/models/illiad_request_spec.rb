# frozen_string_literal: true

require 'rails_helper'

# A fake Request type that can be sent to ILLiad
class ExampleRequest < Request
  include Illiadable
end

RSpec.describe IlliadRequest do
  subject { described_class.new(request) }

  let(:user) { create(:sso_user) }
  let(:patron) { instance_double(Folio::Patron, blocked?: false) }
  let(:request) { ExampleRequest.new(item_id: '1234', bib_data:) }
  let(:bib_data) do
    instance_double(
      Folio::Instance,
      hrid: 'a1234',
      isbn: '978-3-16-148410-0',
      oclcn: '(OCoLC-M)1294477572',
      pub_date: '2018',
      pub_place: 'Berlin',
      publisher: 'Walter de Gruyter GmbH',
      edition: '1st ed.',
      view_url: 'https://searchworks.stanford.edu/view/1234',
      request_holdings: holdings
    )
  end
  let(:holdings) do
    [
      instance_double(
        Folio::Item,
        barcode: '12345678',
        callnumber: 'ABC 321',
        enumeration: 'T.1 2023'
      )
    ]
  end

  before do
    allow(request).to receive(:user).and_return(user)
    allow(user).to receive(:patron).and_return(patron)
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

    it 'specifies that alternate editions are not acceptable by default' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: /"AcceptAlternateEdition":false/)).to have_been_made
    end

    it 'includes the call number' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: /"CallNumber":"ABC 321"/)).to have_been_made
    end

    it 'includes the barcode as the item number' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: /"ItemNumber":"12345678"/)).to have_been_made
    end

    it 'includes the enumeration' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: /"PhotoJournalVolume":"T.1 2023"/)).to have_been_made
    end

    it 'includes the publisher' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: /"LoanPublisher":"Walter de Gruyter GmbH"/)).to have_been_made
    end

    it 'includes the place of publication' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: /"LoanPlace":"Berlin"/)).to have_been_made
    end

    it 'includes the date of publication' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: /"LoanDate":"2018"/)).to have_been_made
    end

    it 'includes the edition' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: /"LoanEdition":"1st ed."/)).to have_been_made
    end

    it 'includes the OCLC number' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: /"ESPNumber":"\(OCoLC-M\)1294477572"/)).to have_been_made
    end

    it 'includes the catalog view link' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: %r{"CitedIn":"https://searchworks.stanford.edu/view/1234"})).to have_been_made
    end

    it 'includes the ISBN' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: /"ISSN":"978-3-16-148410-0"/)).to have_been_made
    end

    context 'when the user is blocked' do
      let(:patron) { instance_double(Folio::Patron, blocked?: true) }

      it 'includes the blocked status' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: /"UserInfo1":"Blocked"/)).to have_been_made
      end
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
