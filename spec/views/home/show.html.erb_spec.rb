# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'home/show' do
  before do
    allow(controller).to receive_messages(current_user: create(:anon_user))
  end

  it 'has title and links' do
    render
    expect(rendered).to have_css('h1', text: 'Request management')
    expect(rendered).to have_css('p.sub-title', text: /Administration and mediation tasks for page/)
  end

  describe 'superadmin' do
    before do
      allow(controller).to receive_messages(current_user: create(:superadmin_user))
      allow(PatronRequest).to receive_messages(mediateable_origins: { 'SAL3' => double(Config::Options, library_override: nil) })
      render
    end

    it 'displays page an administration section' do
      expect(rendered).to have_css('h2', text: 'Administration')
    end

    it 'shows a mediation section if there are mediateable libraries' do
      expect(rendered).to have_css('h2', text: 'Mediation')
    end
  end

  describe 'an anonymous user' do
    before { render }

    it 'does not display page sections' do
      expect(rendered).to have_no_css('h2', text: 'Administration')
      expect(rendered).to have_no_css('h2', text: 'Mediation')
    end

    it 'displays the access error message' do
      expect(rendered).to have_css('p.access-error', text: 'You do not have access')
    end
  end
end
