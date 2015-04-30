require 'rails_helper'

describe 'shared/_webauth_not_you.html.erb' do
  before do
    allow(view).to receive_messages(current_user: user)
  end

  describe 'non-webauth-user' do
    let(:user) { create(:non_webauth_user) }
    it 'should see nothing' do
      render
      expect(rendered).to be_blank
    end
  end

  describe 'webauth user' do
    let(:user) { create(:webauth_user, name: 'Jane Stanford') }
    it 'should see their name, email, and a logout link' do
      render
      expect(rendered).to have_css('h2', text: 'You are logged in as')
      expect(rendered).to have_css('h2', text: 'Jane Stanford')
      expect(rendered).to have_css('h2', text: 'some-webauth-user@stanford.edu')
      expect(rendered).to have_css('a', text: 'Not you?')
    end
  end
end
