# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EadClient do
  describe '.fetch' do
    let(:url) { 'http://example.com/ead.xml' }

    context 'when the URL returns non-EAD XML' do
      before do
        stub_request(:get, url).to_return(status: 200, body: '<html><body>Not found</body></html>')
      end

      it 'raises InvalidDocument' do
        expect { described_class.fetch(url) }.to raise_error(EadClient::InvalidDocument)
      end
    end

    context 'when the URL returns malformed XML' do
      before do
        stub_request(:get, url).to_return(status: 200, body: '<not valid xml <<')
      end

      it 'raises InvalidDocument' do
        expect { described_class.fetch(url) }.to raise_error(EadClient::InvalidDocument)
      end
    end

    context 'when the server returns a non-success status' do
      before do
        stub_request(:get, url).to_return(status: 404)
      end

      it 'raises Error' do
        expect { described_class.fetch(url) }.to raise_error(EadClient::Error)
      end
    end

    context 'when the URL returns valid EAD XML' do
      before do
        stub_request(:get, url).to_return(status: 200, body: File.read('spec/fixtures/a0112.xml'))
      end

      it 'returns an Ead::Document' do
        expect(described_class.fetch(url)).to be_a(Ead::Document)
      end
    end
  end
end
