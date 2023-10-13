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

  describe 'request headers' do
    it 'posts to the ILLiad API sending JSON' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(headers: {
              'Content-Type' => 'application/json',
              'Accept' => 'application/json; version=1',
              'ApiKey' => 'some-api-key'
            })).to have_been_made
    end
  end

  describe 'request body' do
    let(:expected_body) do
      '{"ProcessType":"Borrowing","AcceptAlternateEdition":false,"Username":"some-sso-user",' \
        '"ISSN":"978-3-16-148410-0","LoanPublisher":"Walter de Gruyter GmbH","LoanPlace":"Berlin",' \
        '"LoanDate":"2018","LoanEdition":"1st ed.","ESPNumber":"(OCoLC-M)1294477572",' \
        '"CitedIn":"https://searchworks.stanford.edu/view/1234","CallNumber":"ABC 321",' \
        '"ILLNumber":"12345678","ItemNumber":"12345678","PhotoJournalVolume":"T.1 2023"}'
    end

    it 'includes the expected payload' do
      expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
      .with(body: expected_body)).to have_been_made
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
      let(:expected_body) do
        '{"ProcessType":"Borrowing","AcceptAlternateEdition":false,"Username":"some-sso-user",' \
          '"ISSN":"","LoanEdition":"","ESPNumber":"",' \
          '"CitedIn":"https://searchworks.stanford.edu/view/","CallNumber":"ABC 123",' \
          '"ILLNumber":"12345678","ItemNumber":"12345678","RequestType":"Article",' \
          '"SpecIns":"Scan and Deliver Request","PhotoJournalTitle":"SAL Item Title",' \
          '"PhotoArticleAuthor":"John Q. Public","Location":"SAL3","ReferenceNumber":"SAL3-STACKS",' \
          '"PhotoArticleTitle":"Section Title for Scan 12345","PhotoJournalInclusivePages":"1-10"}'
      end

      it 'includes the request type' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: expected_body)).to have_been_made
      end
    end
  end

  context 'with a hold/recall' do
    let(:request) { create(:hold_recall_checkedout) }

    describe 'request body' do
      let(:expected_body) do
        '{"ProcessType":"Borrowing","AcceptAlternateEdition":false,"Username":"some-sso-user",' \
          '"ISSN":"978-3-16-148410-0","LoanPublisher":"Walter de Gruyter GmbH","LoanPlace":"Berlin",' \
          '"LoanDate":"2018","LoanEdition":"1st ed.","ESPNumber":"(OCoLC-M)1294477572",' \
          '"CitedIn":"https://searchworks.stanford.edu/view/1234","CallNumber":"ABC 321",' \
          '"ILLNumber":"87654321","ItemNumber":"87654321","PhotoJournalVolume":"T.1 2023","RequestType":"Loan",' \
          '"SpecIns":"Hold/Recall Request","LoanTitle":"Checked out item",' \
          '"LoanAuthor":"John Q. Public","NotWantedAfter":"2023-10-13","ItemInfo4":"GREEN"}'
      end

      it 'includes the expected_payload' do
        expect(a_request(:post, 'https://illiad.stanford.edu/ILLiadWebPlatform/Transaction/')
        .with(body: expected_body)).to have_been_made
      end
    end
  end
end
