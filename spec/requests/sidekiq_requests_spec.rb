# frozen_string_literal: true

require 'rails_helper'

describe 'Sidekiq requests' do
  let(:url) { '/sidekiq' }

  context 'with superadmin privileges' do
    it 'is successful' do
      allow(CurrentUser).to receive(:for).and_return(double(super_admin?: true))
      expect { get(url) }.to raise_error(RedisClient::CannotConnectError)
    end
  end

  context 'without superadmin privileges' do
    it 'raises an access denied error' do
      expect { get(url) }.to raise_error(ActionController::RoutingError)
    end
  end
end
