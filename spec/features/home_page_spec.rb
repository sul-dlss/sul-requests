# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home Page' do
  describe 'layout' do
    before do
      visit root_path
    end

    it 'renders the page' do
      expect(page).to have_title('SUL Requests')
      expect(page).to have_css('.sul-logo')
      within('.header-links') do
        expect(page).to have_link('My Account')
        expect(page).to have_link('Feedback')
      end

      # page has a target="_blank" feedback link (with appropriate rel attribute)
      feedback_link = page.find('.header-links a', text: 'Feedback')
      expect(feedback_link['target']).to eq '_blank'
      expect(feedback_link['rel']).to eq 'noopener noreferrer'

      within('#sul-footer') do
        expect(page).to have_css('#sul-footer-img img')
        within('#sul-footer-links') do
          expect(page).to have_link('Hours & locations')
          expect(page).to have_link('My Account')
          expect(page).to have_link('Ask us')
        end
      end

      within('#global-footer') do
        expect(page).to have_css('#bottom-logo img')
        within('#bottom-text') do
          expect(page).to have_link('Stanford Home')
          expect(page).to have_link('Maps & Directions')
          expect(page).to have_link('Search Stanford')
          expect(page).to have_link('Terms of Use')
          expect(page).to have_link('Emergency Info')
        end
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
