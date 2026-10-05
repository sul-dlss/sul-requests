# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::User do
  describe '#stub?' do
    subject(:user) { described_class.from_dynamic(stub_data.merge(data)) }

    let(:stub_data) do
      { 'username' => 'stub@stanford.edu', 'authType' => 'Default', 'eMailAddress' => nil, 'cleared' => 'NEW' }
    end
    let(:data) { {} }

    it 'is true for an SSO account with no email address' do
      expect(user).to be_stub
    end

    context 'with an email address' do
      let(:data) { { 'eMailAddress' => 'stub@stanford.edu' } }

      it { is_expected.not_to be_stub }
    end

    context 'with an Aeon-authenticated account' do
      let(:data) { { 'authType' => 'Aeon' } }

      it { is_expected.not_to be_stub }
    end

    context 'with a blocked account' do
      let(:data) { { 'cleared' => 'B' } }

      it { is_expected.not_to be_stub }
    end

    context 'with a disavowed account' do
      let(:data) { { 'cleared' => 'DIS' } }

      it { is_expected.not_to be_stub }
    end
  end
end
