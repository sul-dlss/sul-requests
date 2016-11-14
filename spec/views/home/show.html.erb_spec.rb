require 'rails_helper'

describe 'home/show' do
  before do
    allow(controller).to receive_messages(current_user: create(:anon_user))
  end
  it 'should have title and links' do
    render
    expect(rendered).to have_css('h1', text: 'Request management')
    expect(rendered).to have_css('p.sub-title', text: /Administration and mediation tasks for page/)
  end
  describe 'superadmin' do
    before do
      allow(controller).to receive_messages(current_user: create(:superadmin_user))
      allow(Request).to receive_messages(mediateable_origins: ['SAL3'])
      render
    end
    it 'should display page an administration section' do
      expect(rendered).to have_css('h2', text: 'Administration')
    end
    it 'should show a mediation section if there are mediateable libraries' do
      expect(rendered).to have_css('h2', text: 'Mediation')
    end
  end
  describe 'an anonymous user' do
    before { render }
    it 'should not display page sections' do
      expect(rendered).to_not have_css('h2', text: 'Administration')
      expect(rendered).to_not have_css('h2', text: 'Mediation')
    end
    it 'should display the access error message' do
      expect(rendered).to have_css('p.access-error', text: 'You do not have access')
    end
  end
end
