require 'rails_helper'

describe 'shared/_top_navbar.html.erb' do
  it 'should have a login link if there is no user' do
    expect(view).to receive_messages(current_user: create(:anon_user))
    render
    expect(rendered).to have_css('a', text: 'Login')
  end
  it 'should have a logout link if there is a user' do
    expect(view).to receive_messages(current_user: create(:webauth_user))
    render
    expect(rendered).to have_css('a', text: 'some-webauth-user: Logout')
  end
end
