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

  describe '#name' do
    it 'joins the first and last names from Aeon' do
      user = described_class.from_dynamic('username' => 'jstanford', 'firstName' => 'Jane', 'lastName' => 'Stanford')

      expect(user.name).to eq 'Jane Stanford'
    end

    it 'omits a missing last name' do
      user = described_class.from_dynamic('username' => 'test', 'firstName' => 'Testing McTesterson', 'lastName' => nil)

      expect(user.name).to eq 'Testing McTesterson'
    end
  end
end
