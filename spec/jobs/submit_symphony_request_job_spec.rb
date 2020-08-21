# frozen_string_literal: true

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
      Sidekiq.logger.level = Logger::UNKNOWN
      allow_any_instance_of(SubmitSymphonyRequestJob::Command).to receive(:client).and_return(test_client)
    end

    let(:user) { build(:non_webauth_user) }
    let(:page) { create(:page_with_holdings, user: user) }

    describe '#perform' do
      it 'merges response information with the existing request data' do
        expect_any_instance_of(page.class).to receive(:merge_symphony_response_data).with(
          hash_including(req_type: 'PAGE')
        ).and_call_original
        subject.perform(page.id)
        page.reload
        expect(page.symphony_response.req_type).to eq 'PAGE'
      end

      it 'calls send_approval_status! on the request object' do
        expect_any_instance_of(page.class).to receive(:send_approval_status!)
        subject.perform(page.id)
      end

      it 'notifies Honeybadger when the request is not found' do
        expect_any_instance_of(Honeybadger).to receive(:notify).once.with(
          'Attempted to call Symphony for Request with ID -1, but no such Request was found.'
        )
        subject.perform(-1)
      end
    end
  end

  describe SubmitSymphonyRequestJob::Command do
    subject { described_class.new(request) }

    let(:user) { build(:non_webauth_user) }
    let(:request) { scan }
    let(:scan) { create(:scan_with_holdings, user: user) }
    let(:hold) { create(:hold_recall_with_holdings, user: user) }
    let(:page) { create(:page_with_holdings, user: user) }

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

      context 'with public (copy) notes' do
        let(:request) do
          page.tap do |x|
            x.update(public_notes: { '111' => 'note for 111', '222' => 'note for 222' })
            x.update(barcodes: %w(111 222))
          end
        end

        it 'copy_note is the public_notes reformatted' do
          expect(subject.request_params).to include(copy_note: '111:note for 111^222:note for 222^')
        end
      end

      it 'contains the request information' do
        expect(subject.request_params).to include ckey: '12345', home_lib: 'SAL3'
        expect(subject.request_params).to include requested_date: %r(\d{2}/\d{2}/\d{4}$)
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

    describe '#copy_notes' do
      it 'returns Array of Strings of format barcode:note' do
        subject.request.update(public_notes: { '111' => 'note for 111', '222' => 'note for 222' })
        subject.request.update(barcodes: %w(111 222))
        expect(subject.send(:copy_notes)).to eq ['111:note for 111', '222:note for 222']
      end

      it 'only includes notes when they are for an included barcode' do
        subject.request.update(public_notes: { '111' => 'note for 111', '222' => 'note for 222' })
        subject.request.update(barcodes: ['111'])
        expect(subject.send(:copy_notes)).to eq ['111:note for 111']
      end

      it 'is empty Array if no barcodes' do
        subject.request.update(public_notes: { '111' => 'note for 111', '222' => 'note for 222' })
        expect(subject.send(:copy_notes)).to eq []
      end

      it 'is nil if no public_notes' do
        subject.request.update(barcodes: %w(111 222))
        expect(subject.send(:copy_notes)).to be_nil
      end
    end
  end

  describe SubmitSymphonyRequestJob::SymWsCommand do
    subject { described_class.new(request, symphony_client: mock_client) }

    let(:user) { build(:non_webauth_user) }
    let(:request) { scan }
    let(:scan) { create(:scan_with_holdings_barcodes, user: user) }
    let(:mock_client) { instance_double(SymphonyClient) }

    describe '#execute!' do
      it 'for each barcode place a hold with symphony' do
        expect(subject.user).to receive(:patron).at_least(3).times.and_return(Patron.new({}))
        allow_any_instance_of(CatalogInfo).to receive(:current_location).and_return('SAL')
        expect(mock_client).to receive(:place_hold).with(
          {
            fill_by_date: nil, key: 'SAL3', recall_status: 'STANDARD',
            item: { itemBarcode: '12345678', holdType: 'COPY' },
            patron_barcode: 'SAL3-SCANDELIVER', comment: 'Jane Stanford jstanford@stanford.edu',
            for_group: false, force: true
          }
        ).and_return({}).ordered
        expect(mock_client).to receive(:place_hold).with(
          {
            fill_by_date: nil, key: 'SAL3', recall_status: 'STANDARD',
            item: { itemBarcode: '87654321', holdType: 'COPY' },
            patron_barcode: 'SAL3-SCANDELIVER', comment: 'Jane Stanford jstanford@stanford.edu',
            for_group: false, force: true
          }
        ).and_return({}).ordered
        subject.execute!
      end

      context 'without barcodes' do
        let(:scan) { create(:scan, user: user) }

        it 'places a hold using a callkey' do
          expect(subject.user).to receive(:patron).at_least(3).times.and_return(Patron.new({}))
          allow_any_instance_of(CatalogInfo).to receive(:current_location).and_return('SAL')
          expect(mock_client).to receive(:bib_info).and_return(
            { 'fields' => { 'callList' => [{ 'key' => 'hello:world' }] } }
          )
          expect(mock_client).to receive(:place_hold).with(
            {
              fill_by_date: nil, key: 'SAL3', recall_status: 'STANDARD',
              item: { call: { key: 'hello:world', resource: '/catalog/call' }, holdType: 'TITLE' },
              patron_barcode: 'SAL3-SCANDELIVER', comment: 'Jane Stanford jstanford@stanford.edu',
              for_group: false, force: true
            }
          ).and_return({})
          subject.execute!
        end
      end
    end
  end
end
