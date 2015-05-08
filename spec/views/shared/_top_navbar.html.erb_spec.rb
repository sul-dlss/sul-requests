require 'rails_helper'

describe 'shared/_top_navbar.html.erb' do
  before do
    expect(view).to receive_messages(current_user: user)
    render
  end
  describe 'login link' do
    let(:user) { create(:anon_user) }
    it 'should have a login link if there is no user' do
      expect(rendered).to have_css('a', text: 'Login')
    end
  end

  describe 'logout link' do
    let(:user) { create(:webauth_user) }
    it 'should have a logout link if there is a user' do
      expect(rendered).to have_css('a', text: 'some-webauth-user: Logout')
    end
    it 'should redirect users back to the home page of the app' do
      expect(rendered).to have_css('a[href="/webauth/logout?referrer=%2F"]')
    end
  end
end
