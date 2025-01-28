# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sidekiq requests' do
  let(:url) { '/sidekiq' }
  let(:user) { nil }

  before do
    login_as(user, run_callbacks: false)
  end

  context 'with superadmin privileges' do
    let(:user) { instance_double(CurrentUser, user_object: instance_double(User, super_admin?: true)) }

    it 'is successful' do
      expect { get(url) }.to raise_error(RedisClient::CannotConnectError)
    end
  end

  context 'without superadmin privileges' do
    it 'raises an access denied error' do
      get(url)
      expect(response).to have_http_status(:not_found)
    end
  end
end
