# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Account do
  subject(:account) do
    described_class.new(fine.with_indifferent_access)
  end

  let(:fine) do
    { 'id' => '4a00ff2c-8a03-4614-8430-e350e8195642',
      'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
      'remaining' => 25,
      'amount' => 25,
      'feeFine' => { 'feeFineType' => 'Manual Replacement Fee' },
      'actions' =>
      [{ 'amountAction' => 25,
         'balance' => 25,
         'id' => 'a0b8d6ae-c7c5-4bda-9405-076d8b21412f',
         'dateAction' => '2023-07-18T00:06:51.538+00:00' }],
      'status' => { 'name' => 'Open' },
      'paymentStatus' => { 'name' => 'Outstanding' },
      'item' =>
      { 'effectiveLocation' => { 'library' => { 'name' => 'Art and Architecture' } },
        'instance' => { 'title' => '"Star shining on the mountain',
                        'contributors' => [{ name: 'Author 1' }, { name: 'Author 2' }] },
        'holdingsRecord' => { 'callNumber' => 'MD 7520' } } }
  end

  let(:payment) do
    { 'id' => '4a00ff2c-8a03-4614-8430-e350e8195642',
      'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
      'remaining' => 0,
      'amount' => 25,
      'feeFine' => { 'feeFineType' => 'Manual Replacement Fee' },
      'actions' =>
      [{ 'amountAction' => 25,
         'balance' => 25,
         'id' => 'a0b8d6ae-c7c5-4bda-9405-076d8b21412f',
         'dateAction' => '2023-07-18T00:06:51.538+00:00' },
       { 'amountAction' => 25,
         'balance' => 0,
         'id' => '86c03816-d7de-471e-a99d-90b3b9b4a5f8',
         'dateAction' => '2023-07-18T00:07:19.517+00:00' }],
      'status' => { 'name' => 'Closed' },
      'paymentStatus' => { 'name' => 'Paid fully' },
      'item' =>
      { 'effectiveLocation' => { 'library' => { 'name' => 'Art and Architecture' } },
        'instance' => { 'title' => '"Star shining on the mountain',
                        'contributors' => [{ name: 'Author 1' }, { name: 'Author 2' }] },
        'holdingsRecord' => { 'callNumber' => 'MD 7520' } } }
  end

  it 'responds to delegated methods' do
    expect(account).to respond_to(:library_name)
    expect(account).to respond_to(:library_code)
    expect(account).to respond_to(:from_ill?)
    expect(account).to respond_to(:effective_location)
    expect(account).to respond_to(:permanent_location)
  end

  describe '#key' do
    subject(:key) { account.key }

    it 'has a key' do
      expect(key).to eq '4a00ff2c-8a03-4614-8430-e350e8195642'
    end
  end

  describe '#author' do
    subject(:author) { account.author }

    context 'when there is an associated item' do
      it 'returns the authors' do
        expect(author).to eq 'Author 1, Author 2'
      end
    end

    context 'when there is no associated item' do
      before do
        fine['item'] = nil
      end

      it 'returns nil' do
        expect(author).to be_nil
      end
    end
  end

  describe '#patron_key' do
    subject(:patron_key) { account.patron_key }

    context 'when the fine is not a proxy fine' do
      it { expect(patron_key).to eq 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f' }
    end

    context 'when the fine is from a proxy checkout' do
      before do
        fine['loan'] = { 'proxyUserId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b' }
      end

      it { expect(patron_key).to eq 'bdfa62a1-758c-4389-ae81-8ddb37860f9b' }
    end
  end

  context 'when the account is paid' do
    subject(:account) do
      described_class.new(payment.with_indifferent_access)
    end

    describe '#payment_amount' do
      subject(:payment_amount) { account.payment_amount }

      context 'when the account was fully paid' do
        it 'is the full amount' do
          expect(payment_amount).to eq 25
        end
      end

      context 'when the account was waived' do
        before do
          payment['paymentStatus']['name'] = 'Waived fully'
        end

        it 'is zero' do
          expect(payment_amount).to eq 0
        end
      end

      context 'when the account was cancelled' do
        before do
          payment['paymentStatus']['name'] = 'Cancelled as error'
        end

        it 'is zero' do
          expect(payment_amount).to eq 0
        end
      end
    end
  end
end
