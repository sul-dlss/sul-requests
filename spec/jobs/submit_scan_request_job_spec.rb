require 'rails_helper'

RSpec.describe SubmitScanRequestJob, type: :job do
  let(:test_client) do
    Faraday.new do |builder|
      builder.adapter :test do |stub|
        stub.get('/func_request_webservice_new.make_request') { |_| [200, {}, '{}'] }
      end
    end
  end

  before do
    allow(Settings.symphony_api).to receive(:url).and_return('http://illiad.ill.example.com/')
  end

  context 'with a stubbed HTTP client' do
    before do
      allow(subject).to receive(:client).and_return(test_client)
    end

    let(:user) { build(:non_webauth_user) }
    let(:scan) { create(:scan_with_holdings, user: user) }

    describe '#perform' do
      it 'submits the request to symphony' do
        subject.perform(scan)
      end
    end

    describe '#request_params' do
      it 'contains the request information' do
        expect(subject.request_params(scan)).to include ckey: '12345', home_lib: 'SAL3'
      end

      context 'with a non-webauth user' do
        it 'contains the patron information' do
          expect(subject.request_params(scan)).to include patron_name: user.name, patron_email: user.email
        end
      end

      context 'with a library id user' do
        let(:user) { build(:non_webauth_user, library_id: '12345') }

        it 'contains the patron information' do
          expect(subject.request_params(scan)).to include library_id: '12345'
        end
      end

      context 'with a webauth user' do
        let(:user) { build(:webauth_user, library_id: '98765') }

        it 'contains the patron information' do
          expect(subject.request_params(scan)).to include library_id: user.library_id, sunet_id: user.webauth
        end
      end

      context 'without requested items' do
        it 'contains the NO_ITEMS placeholder' do
          expect(subject.request_params(scan)).to include items: 'NO_ITEMS^'
        end
      end

      context 'with requested barcodes' do
        let(:scan) { create(:scan_with_holdings_barcode, user: user) }

        it 'contains the item barcode' do
          expect(subject.request_params(scan)).to include items: '12345678^'
        end
      end
    end
  end

  describe '#client' do
    it 'provides an HTTP client for the given base URL' do
      expect(subject.send(:client).url_prefix.to_s).to eq Settings.symphony_api.url
    end
  end
end
