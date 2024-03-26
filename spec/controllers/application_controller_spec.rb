# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController do
  describe '#current_user' do
    before do
      warden.set_user(CurrentUser.new({ 'username' => 'test', 'shibboleth' => true }))
    end

    it 'returns an application user object when there is a logged-in user' do
      expect(controller.current_user).to have_attributes(sso_user?: true, sunetid: 'test')
    end
  end
end
