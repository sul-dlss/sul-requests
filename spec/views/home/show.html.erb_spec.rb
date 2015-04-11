require 'rails_helper'

describe 'home/show' do
  let(:current_user) { User.new }
  before do
    allow(controller).to receive(:current_user).and_return(current_user)
  end
  it 'should have title and links' do
    render
    expect(rendered).to have_css('h1', text: 'Request management')
    expect(rendered).to have_css('h4', text: /^Administration and mediation tasks for page/)
  end
  describe 'superadmin' do
    before do
      allow(current_user).to receive_messages(superadmin?: true)
      render
    end
    it 'should display page sections' do
      expect(rendered).to have_css('h2', text: 'Administration')
      expect(rendered).to have_css('h2', text: 'Mediation')
    end
  end
  describe 'an anonymous user' do
    before { render }
    it 'should display page sections' do
      expect(rendered).to_not have_css('h2', text: 'Administration')
      expect(rendered).to_not have_css('h2', text: 'Mediation')
    end
    it 'should display the access error message' do
      expect(rendered).to have_css('h4.access-error', text: 'You do not have access')
    end
  end
end
