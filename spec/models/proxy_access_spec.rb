# frozen_string_literal: true

require 'rails_helper'

describe ProxyAccess do
  describe 'status' do
    before do
      allow(subject).to receive(:response).and_return(response)
    end

    let(:response) { double(body: '') }

    context 'for a patron who sponsors a proxy group' do
      let(:response) { double(body: 'MY_PROXY_GROUP|SPONSOR|group_notice@lists.stanford.edu|') }

      it { is_expected.to be_sponsor }
      it { is_expected.not_to be_proxy }

      it 'has the notification list' do
        expect(subject.email_address).to eq 'group_notice@lists.stanford.edu'
      end
    end

    context 'for a library id in a proxy group' do
      let(:response) { double(body: 'MY_PROXY_GROUP|PROXY|group_notice@lists.stanford.edu|') }

      it { is_expected.not_to be_sponsor }
      it { is_expected.to be_proxy }

      it 'has the notification list' do
        expect(subject.email_address).to eq 'group_notice@lists.stanford.edu'
      end

      it 'has a name' do
        expect(subject.name).to eq 'MY_PROXY_GROUP'
      end
    end

    context 'for a patron without a proxy status' do
      it { is_expected.not_to be_sponsor }
      it { is_expected.not_to be_proxy }
    end
  end

  context 'without a configured api endpoint' do
    it { is_expected.not_to be_sponsor }
    it { is_expected.not_to be_proxy }
  end

  describe '#request_url' do
    before do
      allow(Settings).to receive(:sul_proxy_api_url).and_return('http://some/url/?libid=%{libid}')
    end

    it 'interpolates the request url using the provided libid' do
      subject.libid = '123'
      expect(subject.send(:request_url)).to eq 'http://some/url/?libid=123'
    end

    it 'escapes the libid parameter' do
      subject.libid = '1 2&3'
      expect(subject.send(:request_url)).to eq 'http://some/url/?libid=1%202%263'
    end
  end

  describe 'response error handling' do
    context 'when we are unable to connect to the api' do
      before do
        allow(Settings).to receive(:sul_proxy_api_url).and_return('http://some/url/?libid=%{libid}')
        expect(Faraday.default_connection).to receive(:get).and_raise(Faraday::Error::ConnectionFailed, '')
      end

      it { is_expected.not_to be_sponsor }
      it { is_expected.not_to be_proxy }
    end

    context 'when the api return a failure' do
      before do
        allow(Settings).to receive(:sul_proxy_api_url).and_return('http://some/url/?libid=%{libid}')
        expect(Faraday.default_connection).to receive(:get).and_return(response)
      end

      let(:response) { double(success?: false, body: '') }

      it { is_expected.not_to be_sponsor }
      it { is_expected.not_to be_proxy }
    end

    context 'when the api is functional' do
      before do
        allow(Settings).to receive(:sul_proxy_api_url).and_return('http://some/url/?libid=%{libid}')
        expect(Faraday.default_connection).to receive(:get).and_return(response)
      end

      let(:response) { double(success?: true, body: '') }

      it { is_expected.not_to be_sponsor }
      it { is_expected.not_to be_proxy }
    end
  end
end
