# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FolioClient do
  subject(:client) { described_class.new(url:) }

  let(:url) { 'https://okapi.example.edu' }

  before do
    stub_request(:post, 'https://okapi.example.edu/authn/login')
      .to_return(headers: { 'x-okapi-token': 'tokentokentoken' }, status: 201)
  end

  describe '#inspect' do
    subject { described_class.new.inspect }

    it { is_expected.not_to include 'pass' }
  end

  describe '#renew_items' do
    subject(:renew_items) { client.renew_items(checkouts) }

    let(:checkouts) do
      [double(patron_key: '9af85395-3104-5fc9-88ab-15554765c2d2', item_id: '6d9a4f99-d144-51cf-92d7-3edbfc588abe'),
       double(patron_key: '9af85395-3104-5fc9-88ab-15554765c2d2', item_id: 'cc3d8728-a6b9-45c4-ad0c-432873c3ae47')]
    end
    let(:record_one) do
      { 'item' => { 'itemId' => '6d9a4f99-d144-51cf-92d7-3edbfc588abe' },
        'details' => { 'userId' => '9af85395-3104-5fc9-88ab-15554765c2d2' } }
    end
    let(:record_two) do
      { 'item' => { 'itemId' => 'cc3d8728-a6b9-45c4-ad0c-432873c3ae47' },
        'details' => { 'userId' => '9af85395-3104-5fc9-88ab-15554765c2d2' } }
    end

    before do
      stub_request(:post, 'https://okapi.example.edu/circulation/renew-by-id')
        .with(body: { itemId: record_one.dig('item', 'itemId'), userId: record_one.dig('details', 'userId') },
              headers: { 'x-okapi-token': 'tokentokentoken', 'X-Okapi-Tenant': 'sul' })
        .to_return(body: {}.to_json, status: 200)

      stub_request(:post, 'https://okapi.example.edu/circulation/renew-by-id')
        .with(body: { itemId: record_two.dig('item', 'itemId'), userId: record_two.dig('details', 'userId') },
              headers: { 'x-okapi-token': 'tokentokentoken', 'X-Okapi-Tenant': 'sul' })
        .to_return(body: {}.to_json, status: 422)
    end

    it 'groups the successful and failed renewal responses' do
      expect(renew_items[:success].count).to eq 1
      expect(renew_items[:success].first.item_id).to eq '6d9a4f99-d144-51cf-92d7-3edbfc588abe'
      expect(renew_items[:error].count).to eq 1
      expect(renew_items[:error].first.item_id).to eq 'cc3d8728-a6b9-45c4-ad0c-432873c3ae47'
    end
  end

  describe '#renew_item_by_id' do
    subject(:renew_item) { client.renew_item_by_id(user_id, item_id) }

    let(:status) { 200 }
    let(:user_id) { '9af85395-3104-5fc9-88ab-15554765c2d2' }
    let(:item_id) { 'cc3d8728-a6b9-45c4-ad0c-432873c3ae47' }

    before do
      stub_request(:post, 'https://okapi.example.edu/circulation/renew-by-id')
        .with(body: { itemId: item_id, userId: user_id },
              headers: { 'x-okapi-token': 'tokentokentoken', 'X-Okapi-Tenant': 'sul' })
        .to_return(body: {}.to_json, status:)
    end

    it 'returns a successful renewal response' do
      expect(renew_item.status).to eq(200)
    end

    context 'when the renewal fails' do
      let(:status) { 422 }

      it 'returns the failed renewal response' do
        expect(renew_item.status).to eq(422)
      end
    end
  end
end
