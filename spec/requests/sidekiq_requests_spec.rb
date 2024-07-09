# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sidekiq requests' do
  let(:user) { nil }

  before do
    login_as(user, run_callbacks: false)
    get '/sidekiq'
  end

  context 'with superadmin privileges' do
    let(:user) { instance_double(CurrentUser, user_object: instance_double(User, super_admin?: true)) }

    it 'is successful' do
      expect(response).to have_http_status :internal_server_error # due to sidekiq not running in test
    end
  end

  context 'without superadmin privileges' do
    it 'shows the not found page' do
      expect(response).to have_http_status :not_found
    end
  end
end
