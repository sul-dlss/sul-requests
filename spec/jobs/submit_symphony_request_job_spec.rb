# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitSymphonyRequestJob, type: :job do
  before do
    allow(Settings.ils).to receive(:request_job).and_return(described_class)
  end

  context 'with a stubbed HTTP client' do
    before do
      Sidekiq.logger.level = Logger::UNKNOWN
    end

    let(:user) { build(:non_sso_user) }
    let(:request) { create(:page_with_holdings, user:) }

    describe '#perform' do
      let(:mock_client) { instance_double(SymphonyClient) }

      before do
        allow(mock_client).to receive(:place_hold).and_return({})
        allow(mock_client).to receive(:bib_info).and_return({})
        allow_any_instance_of(SubmitSymphonyRequestJob::Command).to receive(:symphony_client).and_return(mock_client)
      end

      it 'calls send_approval_status! on the request object' do
        expect_any_instance_of(request.class).to receive(:send_approval_status!)
        subject.perform(request.id)
      end

      it 'notifies Honeybadger when the request is not found' do
        expect_any_instance_of(Honeybadger).to receive(:notify).once.with(
          'Attempted to call Symphony for Request with ID -1, but no such Request was found.'
        )
        subject.perform(-1)
      end
    end
  end

  describe SubmitSymphonyRequestJob::SymWsCommand do
    subject { described_class.new(request, symphony_client: mock_client) }

    let(:user) { build(:non_sso_user) }
    let(:request) { scan }
    let(:scan) { create(:scan_with_holdings_barcodes, user:) }
    let(:mock_client) { instance_double(SymphonyClient) }
    let(:patron) { Symphony::Patron.new({}) }

    before do
      allow(user).to receive(:patron).and_return(patron)
    end

    describe '#execute!' do
      it 'for each barcode place a hold with symphony' do
        allow_any_instance_of(Symphony::CatalogInfo).to receive(:current_location).and_return('SAL')
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

      context 'for a patron with a library id' do
        let(:user) { build(:sso_user) }
        let(:request) { create(:page_with_holdings, user:) }
        let(:patron) do
          Symphony::Patron.new({
                                 'fields' => {
                                   'barcode' => '12345',
                                   'standing' => { 'key' => 'OK' }
                                 }
                               })
        end

        before do
          allow(mock_client).to receive(:bib_info).and_return({})
        end

        it 'places the request on behalf of the patron' do
          expect(mock_client).to receive(:place_hold) do |**params|
            expect(params).to include(
              patron_barcode: '12345',
              recall_status: 'STANDARD'
            )
          end.and_return({})

          subject.execute!
        end
      end

      context 'for a sunetid patron without a library id' do
        let(:user) { build(:sso_user) }
        let(:request) { create(:page_with_holdings, user:) }

        before do
          allow(mock_client).to receive(:bib_info).and_return({})
        end

        it 'places the request on behalf of a pseudopatron and lets the circ desk figure it out' do
          allow(user).to receive(:patron).and_return(nil)
          expect(mock_client).to receive(:place_hold) do |**params|
            expect(params).to include(
              comment: ' some-sso-user@stanford.edu',
              patron_barcode: 'HOLD@AR',
              recall_status: 'STANDARD'
            )
          end.and_return({})

          subject.execute!
        end
      end

      context 'for a response where the user already has a hold on the material' do
        let(:request) { create(:page_with_holdings, user:) }

        before do
          allow(mock_client).to receive(:bib_info).and_return({})
          expect(mock_client).to receive(:place_hold).at_least(:once).and_return(
            {
              'messageList' => [
                { 'message' => 'User already has a hold on this material', 'code' => 'hatErrorResponse.722' }
              ]
            }
          )
        end

        context 'when a typical user' do
          let(:patron) do
            Symphony::Patron.new(
              { 'fields' => { 'barcode' => '123456', 'standing' => { 'key' => 'OK' } } }
            )
          end

          it 'but does not notify staff' do
            expect do
              subject.execute!
            end.not_to change { MultipleHoldsMailer.deliveries.count }
          end
        end

        context 'when the patron barcode begins with "HOLD@"' do
          it 'notifies staff' do
            allow(subject.user).to receive(:patron).and_return(Symphony::Patron.new({}))

            expect do
              subject.execute!
            end.to change { MultipleHoldsMailer.deliveries.count }.by(1)
          end
        end

        context 'when the item is a scan' do
          let(:request) { scan }

          it 'does not notify staff' do
            expect do
              subject.execute!
            end.not_to change { MultipleHoldsMailer.deliveries.count }
          end
        end
      end

      context 'for a response from symphony where the record is currently in use' do
        let(:request) { create(:page_with_holdings, user:) }

        before do
          allow(mock_client).to receive(:bib_info).and_return({})
          expect(mock_client).to receive(:place_hold).and_return(
            { # first request
              'messageList' => [
                { 'message' => 'The record is currently in use', 'code' => 'hatErrorResponse.116' }
              ]
            },
            {
              # second request
            }
          )
        end

        it 'retries the request' do
          response = subject.execute!

          expect(response.dig(:requested_items, 0, :msgcode)).to eq '209'
        end
      end

      context 'without barcodes' do
        let(:scan) { create(:scan_with_holdings, user:) }

        it 'places a hold using a callkey' do
          allow_any_instance_of(Symphony::CatalogInfo).to receive(:current_location).and_return('SAL')
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
