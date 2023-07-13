# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitSymphonyRequestJob, if: Settings.ils.request_job == 'SubmitSymphonyRequestJob', type: :job do
  before do
    allow(Settings.ils).to receive(:request_job).and_return(described_class.to_s)
  end

  context 'with a stubbed HTTP client' do
    let(:user) { build(:non_sso_user) }
    let(:request) { create(:page_with_holdings, user:) }

    describe '#perform' do
      context 'when the request is found' do
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
      end

      context 'when the request is not found' do
        it 'notifies Honeybadger' do
          expect_any_instance_of(Honeybadger).to receive(:notify).once.with(
            'Attempted to call Symphony for Request with ID -1, but no such Request was found.'
          )
          subject.perform(-1)
        end
      end
    end
  end

  describe SubmitSymphonyRequestJob::SymWsCommand do
    subject { described_class.new(request, symphony_client: mock_client) }

    let(:user) { build(:non_sso_user) }
    let(:request) { create(:page, bib_data: build(:multiple_holdings), barcodes: ['3610512345678', '3610587654321'], user:) }
    let(:mock_client) { instance_double(SymphonyClient, bib_info: {}) }
    let(:patron) { Symphony::Patron.new({}) }

    before do
      allow(user).to receive(:patron).and_return(patron)
    end

    describe '#execute!' do
      it 'for each barcode place a hold with symphony' do
        expect(mock_client).to receive(:place_hold).with(
          {
            fill_by_date: nil, key: 'ART', recall_status: 'STANDARD',
            item: { holdType: 'COPY', itemBarcode: '3610512345678' },
            patron_barcode: 'HOLD@AR', comment: 'Jane Stanford jstanford@stanford.edu',
            for_group: false, force: true
          }
        ).and_return({}).ordered
        expect(mock_client).to receive(:place_hold).with(
          {
            fill_by_date: nil, key: 'ART', recall_status: 'STANDARD',
            item: { holdType: 'COPY', itemBarcode: '3610587654321' },
            patron_barcode: 'HOLD@AR', comment: 'Jane Stanford jstanford@stanford.edu',
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
            end.not_to have_enqueued_mail
          end
        end

        context 'when the patron barcode begins with "HOLD@"' do
          it 'notifies staff' do
            allow(subject.user).to receive(:patron).and_return(Symphony::Patron.new({}))

            expect do
              subject.execute!
            end.to have_enqueued_mail(MultipleHoldsMailer)
          end
        end

        context 'when the item is a scan' do
          let(:request) do
            create(:scan, :with_holdings_barcodes, origin: 'SAL', origin_location: 'SAL-TEMP', bib_data: build(:scannable_only_holdings),
                                                   user:)
          end

          it 'does not notify staff' do
            expect do
              subject.execute!
            end.not_to have_enqueued_mail
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
        let(:request) do
          create(:scan, :with_holdings, origin: 'SAL', origin_location: 'SAL-TEMP', bib_data: build(:scannable_only_holdings), user:)
        end

        it 'places a hold using a callkey' do
          allow_any_instance_of(Symphony::CatalogInfo).to receive(:current_location).and_return('SAL')
          expect(mock_client).to receive(:bib_info).and_return(
            { 'fields' => { 'callList' => [{ 'key' => 'hello:world' }] } }
          )
          expect(mock_client).to receive(:place_hold).with(
            {
              fill_by_date: nil, key: 'GREEN', recall_status: 'STANDARD',
              item: { call: { key: 'hello:world', resource: '/catalog/call' }, holdType: 'TITLE' },
              patron_barcode: 'GRE-SCANDELIVER', comment: 'Jane Stanford jstanford@stanford.edu',
              for_group: false, force: true
            }
          ).and_return({})
          subject.execute!
        end
      end
    end
  end
end
