# frozen_string_literal: true

require 'rails_helper'

describe 'User Authorization' do
  describe 'login' do
    it 'is present in the home page and redirects with message' do
      visit root_path
      click_link 'Login'
      within('.flashes') do
        expect(page).to have_css('.alert-success', text: 'You have been successfully logged in.')
      end
    end
  end

  describe 'logout' do
    before do
      stub_current_user(create(:webauth_user))
    end

    it 'is present in the home page' do
      visit root_path
      expect(page).to have_link 'some-webauth-user: Logout'
      # We don't test clicking on the link because Shibboleth provides the logout page
    end
  end
end
