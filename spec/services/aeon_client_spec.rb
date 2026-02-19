# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AeonClient do
  subject(:client) { described_class.new(url: 'https://aeon.example.com/api', api_key: 'secret-key') }

  describe '#inspect' do
    it 'does not leak the API key' do
      expect(client.inspect).not_to include('secret-key')
    end
  end

  describe '#find_user' do
    it 'returns a user when found' do
      stub_request(:get, 'https://aeon.example.com/api/Users/jdoe')
        .to_return(status: 200, body: { username: 'jdoe', authType: 'Default' }.to_json, headers: { 'Content-Type' => 'application/json' })

      user = client.find_user(username: 'jdoe')

      expect(user).to be_a(Aeon::User)
      expect(user.username).to eq('jdoe')
      expect(user.auth_type).to eq('Default')
    end

    it 'raises NotFoundError when user is not found' do
      stub_request(:get, 'https://aeon.example.com/api/Users/unknown')
        .to_return(status: 404, body: { error: 'User not found' }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect do
        client.find_user(username: 'unknown')
      end.to raise_error(AeonClient::NotFoundError, 'No Aeon account found for unknown')
    end
  end

  describe '#create_user' do
    it 'creates and returns a new user' do
      stub_request(:post, 'https://aeon.example.com/api/Users')
        .with(body: { username: 'newuser', authType: 'Default', cleared: 'No' }.to_json)
        .to_return(status: 201, body: { username: 'newuser',
                                        authType: 'Default' }.to_json, headers: { 'Content-Type' => 'application/json' })

      user = client.create_user(username: 'newuser')

      expect(user).to be_a(Aeon::User)
      expect(user.username).to eq('newuser')
      expect(user.auth_type).to eq('Default')
    end
  end

  describe '#requests_for' do
    it 'returns an array of requests for the user' do
      stub_request(:get, 'https://aeon.example.com/api/Users/jdoe/requests?activeOnly=false')
        .to_return(status: 200, body: [{ transactionNumber: '123', creationDate: '2024-01-01T12:00:00Z',
                                         transactionDate: '2024-01-01T12:00:00Z',
                                         username: 'jdoe' }].to_json, headers: { 'Content-Type' => 'application/json' })

      requests = client.requests_for(username: 'jdoe')

      expect(requests).to be_an(Array)
      expect(requests.first).to be_a(Aeon::Request)
      expect(requests.first.transaction_number).to eq('123')
    end

    it 'returns an empty array if the API returns a 404' do
      stub_request(:get, 'https://aeon.example.com/api/Users/jdoe/requests?activeOnly=false')
        .to_return(status: 404, body: { error: 'No requests found' }.to_json, headers: { 'Content-Type' => 'application/json' })

      requests = client.requests_for(username: 'jdoe')

      expect(requests).to eq([])
    end
  end

  describe '#create_request' do
    it 'submits a request and returns the created request' do
      payload = AeonClient::CreateRequestData.with_defaults.with(
        username: 'jdoe',
        item_title: 'Test Request'
      )

      stub_request(:post, 'https://aeon.example.com/api/Requests/create')
        .with(body: payload.as_json.to_json)
        .to_return(status: 201,
                   body: { transactionNumber: '123', creationDate: '2024-01-01T12:00:00Z',
                           transactionDate: '2024-01-01T12:00:00Z',
                           username: 'jdoe' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      request = client.create_request(payload)

      expect(request).to be_a(Aeon::Request)
      expect(request.transaction_number).to eq('123')
    end
  end

  describe '#update_request_route' do
    it 'sends a route update and returns the updated request' do
      stub_request(:post, 'https://aeon.example.com/api/Requests/123/route')
        .with(body: { newStatus: 'Cancelled by user' }.to_json)
        .to_return(status: 200,
                   body: { transactionNumber: '123', creationDate: '2024-01-01T12:00:00Z',
                           transactionDate: '2024-01-01T12:00:00Z',
                           username: 'jdoe', transactionStatus: 'Cancelled by user' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      request = client.update_request_route(transaction_number: '123', status: 'Cancelled by user')

      expect(request).to be_a(Aeon::Request)
      expect(request.transaction_number).to eq('123')
      expect(request.transaction_status).to eq('Cancelled by user')
    end
  end
end
