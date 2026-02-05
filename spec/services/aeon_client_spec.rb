# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AeonClient do
  subject(:client) { described_class.new(url: 'https://aeon.example.com/api', api_key: 'secret-key') }

  describe '#inspect' do
    it 'does not leak the API key' do
      expect(client.inspect).not_to include('secret-key')
    end
  end
end
