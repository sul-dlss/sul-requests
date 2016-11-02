require 'rails_helper'

RSpec.describe SubmitSymphonyRequestJob, type: :job do
  let(:test_client) do
    Faraday.new do |builder|
      builder.adapter :test do |stub|
        stub.get('/func_request_webservice_new.make_request') do |_|
          [200, {}, { request_response: { req_type: 'PAGE' } }.to_json]
        end
      end
    end
  end

  before do
    allow(Settings.symphony_api).to receive(:url).and_return('http://illiad.ill.example.com/')
  end

  context 'with a stubbed HTTP client' do
    before do
      allow_any_instance_of(SubmitSymphonyRequestJob::Command).to receive(:client).and_return(test_client)
    end

    let(:user) { build(:non_webauth_user) }
    let(:page) { create(:page_with_holdings, user: user) }

    describe '#perform' do
      it 'merges response information with the existing request data' do
        expect(page).to receive(:merge_symphony_response_data).with(hash_including(req_type: 'PAGE')).and_call_original
        subject.perform(page)
        expect(page.symphony_response.req_type).to eq 'PAGE'
      end
    end
  end

  describe SubmitSymphonyRequestJob::Command do
    let(:user) { build(:non_webauth_user) }
    let(:request) { scan }
    let(:scan) { create(:scan_with_holdings, user: user) }
    let(:hold) { create(:hold_recall_with_holdings, user: user) }
    let(:page) { create(:page_with_holdings, user: user) }

    subject { described_class.new(request) }

    describe '#client' do
      it 'provides an HTTP client for the given base URL' do
        expect(subject.send(:client).url_prefix.to_s).to eq Settings.symphony_api.url
      end
    end

    describe '#request_params' do
      before do
        allow(subject).to receive(:client).and_return(test_client)
      end

      context 'with a scan' do
        let(:request) { scan }
        it 'req_type is the request type' do
          expect(subject.request_params).to include req_type: 'SCAN'
        end
      end

      context 'with a hold' do
        let(:request) { hold }

        it 'req_type is the request type' do
          expect(subject.request_params).to include req_type: 'HOLD'
        end
      end

      context 'with a page' do
        let(:request) { page }

        it 'req_type is the request type' do
          expect(subject.request_params).to include req_type: 'PAGE'
        end
      end

      context 'with item comment' do
        let(:request) { page.tap { |x| x.update(item_comment: 'Item Comment') } }

        it 'item_comments is the item comments' do
          expect(subject.request_params).to include item_comments: 'Item Comment'
        end
      end

      context 'with request comment' do
        let(:request) { page.tap { |x| x.update(request_comment: 'Request Comment') } }

        it 'req_comment is the request comment' do
          expect(subject.request_params).to include req_comment: 'Request Comment'
        end
      end

      it 'contains the request information' do
        expect(subject.request_params).to include ckey: '12345', home_lib: 'SAL3'
      end

      context 'with a non-webauth user' do
        it 'contains the patron information' do
          expect(subject.request_params).to include patron_name: user.name, patron_email: user.email
        end
      end

      context 'with a library id user' do
        let(:user) { build(:non_webauth_user, library_id: '12345') }

        it 'contains the patron information' do
          expect(subject.request_params).to include library_id: '12345'
        end
      end

      context 'with a webauth user' do
        let(:user) { build(:webauth_user, library_id: '98765') }

        it 'contains the patron information' do
          expect(subject.request_params).to include library_id: user.library_id, sunet_id: user.webauth
        end
      end

      context 'without requested items' do
        it 'items is NO_ITEMS placeholder' do
          expect(subject.request_params).to include items: 'NO_ITEMS^'
        end

        it 'items is NO_ITEMS placeholder when the only barcode is blank' do
          request.barcodes = ['']
          expect(subject.request_params).to include items: 'NO_ITEMS^'
        end
      end

      context 'with requested barcodes' do
        let(:scan) { create(:scan_with_holdings_barcodes, user: user) }

        it 'items is the item barcodes separated by ^' do
          expect(subject.request_params).to include items: '12345678^87654321^'
        end
      end
    end
  end
end
