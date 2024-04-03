# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_sul_header.html.erb' do
  before do
    allow(view).to receive_messages(current_user: user)
    allow(view).to receive_messages(current_user?: user.sunetid.present?)
    render
  end

  describe 'logout link' do
    let(:user) { create(:sso_user) }

    it 'has a logout link if there is a user' do
      expect(rendered).to have_css('a', text: 'some-sso-user: Logout')
    end

    it 'redirects users back to the home page of the app' do
      expect(rendered).to have_link('Logout')
    end
  end
end
