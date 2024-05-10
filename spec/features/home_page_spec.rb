# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home Page' do
  describe 'layout' do
    before do
      visit root_path
    end

    it 'renders the page' do
      expect(page).to have_title('Requests : Stanford Libraries')
      expect(page).to have_css('.sul-logo')
      expect(page).to have_link('My Account')
      expect(page).to have_link('Feedback')

      within('#su-footer') do
        expect(page).to have_css('.su-logo')
        expect(page).to have_link('Stanford Home')
        expect(page).to have_link('Maps & Directions')
        expect(page).to have_link('Search Stanford')
        expect(page).to have_link('Terms of Use')
        expect(page).to have_link('Emergency Info')
      end
    end
  end

  describe 'mediation section' do
    before do
      create(:mediated_page)
      create(:page_mp_mediated_page)
      stub_current_user(create(:superadmin_user))
      visit root_path
    end

    it 'has admin links for the library level mediation' do
      expect(page).to have_link('Art & Architecture Library (Bowes)', href: '/admin/ART')
      expect(page).to have_link('Earth Sciences Library (Branner)', href: '/admin/SAL3-PAGE-MP')
    end
  end
end
