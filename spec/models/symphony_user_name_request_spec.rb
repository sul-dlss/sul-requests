# frozen_string_literal: true

require 'rails_helper'

describe SymphonyUserNameRequest do
  subject { described_class.new(libid: '12345') }

  describe 'name and email', allow_apis: true do
    before do
      allow(Settings).to receive(:sul_user_name_api_url).and_return('http://example.com/url/?libid=%{libid}')
    end

    context 'for a library id user' do
      let(:response) { double(success?: true, body: 'Some Patron (email@example.com)') }

      before do
        expect(Faraday.default_connection).to receive(:get).and_return(response)
      end

      it 'has a name' do
        expect(subject.name).to eq 'Some Patron'
      end

      it 'has an email' do
        expect(subject.email).to eq 'email@example.com'
      end

      it { expect(subject.exists?).to be true }
    end

    context 'for an error response' do
      let(:response) { double(success?: false, body: '') }

      before do
        expect(Faraday.default_connection).to receive(:get).and_return(response)
      end

      it 'is blank' do
        expect(subject.name).to be_blank
        expect(subject.email).to be_blank
      end

      it { expect(subject.exists?).to be false }
    end

    context 'for a failed response' do
      before do
        expect(Faraday.default_connection).to receive(:get).and_raise(Faraday::ConnectionFailed, '')
      end

      let(:response) { double(success?: false, body: '') }

      it 'is blank' do
        expect(subject.name).to be_blank
        expect(subject.email).to be_blank
      end

      it { expect(subject.exists?).to be false }
    end
  end
end
