# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomeController do
  describe '#show' do
    it 'is successful' do
      get :show
      expect(response).to be_successful
    end
  end

  describe 'bot challenge' do
    before do
      allow(BotChallengePage::BotChallengePageController.bot_challenge_config).to receive(:enabled).and_return(true)
      allow(controller).to receive(:load_dashboard)
    end

    it 'challenges an anonymous visitor' do
      get :show
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not challenge a logged-in user' do
      stub_current_user(create(:library_id_user))
      get :show
      expect(response).to be_successful
    end
  end
end
