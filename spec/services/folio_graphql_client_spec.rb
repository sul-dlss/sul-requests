# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FolioGraphqlClient do
  subject(:client) { described_class.new(url:) }

  let(:url) { 'https://graphql.example.edu' }
  let(:patron_uuid) { '562a5cb0-e998-4ea2-80aa-34ac2b536238' }

  describe '#patron_graphql_response' do
    subject(:response) { client.patron_graphql_response(patron_uuid) }

    context 'when both user and patron nodes are returned' do
      before do
        stub_request(:post, 'https://graphql.example.edu/')
          .to_return(
            body: {
              data: {
                user: { 'id' => patron_uuid, 'username' => 'jdoe', 'patronGroupId' => 'pg-uuid' },
                patron: { 'id' => patron_uuid, 'holds' => [], 'accounts' => [], 'loans' => [{ 'id' => 'loan-1' }] }
              }
            }.to_json,
            status: 200
          )
      end

      it 'merges the user node under the "user" key in the patron node' do
        expect(response).to include(
          'id' => patron_uuid,
          'holds' => [],
          'accounts' => [],
          'loans' => [{ 'id' => 'loan-1' }],
          'user' => { 'id' => patron_uuid, 'username' => 'jdoe', 'patronGroupId' => 'pg-uuid' }
        )
      end
    end

    context 'when the response body is empty' do
      before do
        stub_request(:post, 'https://graphql.example.edu/').to_return(body: '', status: 200)
      end

      it { is_expected.to be_nil }
    end

    context 'when the user node is nil (patron not found)' do
      before do
        stub_request(:post, 'https://graphql.example.edu/')
          .to_return(body: { data: { user: nil, patron: nil } }.to_json, status: 200)
      end

      it { is_expected.to be_nil }
    end

    context 'when the patron node is nil but the user node is present' do
      before do
        stub_request(:post, 'https://graphql.example.edu/')
          .to_return(
            body: { data: { user: { 'id' => patron_uuid }, patron: nil } }.to_json,
            status: 200
          )
      end

      it 'returns a response with just the user node' do
        expect(response).to eq('user' => { 'id' => patron_uuid })
      end
    end

    context 'when the response includes GraphQL errors' do
      before do
        stub_request(:post, 'https://graphql.example.edu/')
          .to_return(
            body: {
              errors: [{ 'message' => 'something went wrong' }],
              data: { user: { 'id' => patron_uuid }, patron: { 'id' => patron_uuid, 'holds' => [] } }
            }.to_json,
            status: 200
          )
        allow(Honeybadger).to receive(:notify)
      end

      it 'notifies Honeybadger with the error messages' do
        response
        expect(Honeybadger).to have_received(:notify).with('something went wrong', context: { patron_uuid: })
      end

      it 'still returns the merged response' do
        expect(response).to include('id' => patron_uuid, 'user' => { 'id' => patron_uuid })
      end
    end
  end
end
