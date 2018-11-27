# frozen_string_literal: true

require 'rails_helper'
describe SorryController, type: :controller do
  describe 'get #unable' do
    it 'returns http forbidden and shows the please_contact info' do
      get :unable
      expect(response).to have_http_status(:internal_server_error)
    end
  end
end
