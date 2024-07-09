# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new request' do
  let(:url) { '/requests/new' }
  let(:user) { nil }

  before do
    login_as(user, run_callbacks: false)
    get '/patron_requests/new?instance_hrid=%22p3nr6p&origin_location_code=SPEC-SAL3-U-ARCHIVES'
  end

  it 'prevents graphql injection' do
    expect(response).to have_http_status :bad_request
  end
end
