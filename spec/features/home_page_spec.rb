# frozen_string_literal: true

require 'rails_helper'

describe 'Home Page' do
  describe 'layout' do
    before do
      visit root_path
    end

    it 'has the application name as the page title' do
      expect(page).to have_title('SUL Requests')
    end

    it 'displays logo' do
      expect(page).to have_css('header.header-logo')
    end

    it 'displays top menu links' do
      expect(page).to have_css('.header-links a', text: 'My Account')
      expect(page).to have_css('.header-links a', text: 'Feedback')
    end

    it 'has a target="_blank" feedback link (with appropriate rel attribute)' do
      feedback_link = page.find('.header-links a', text: 'Feedback')
      expect(feedback_link['target']).to eq '_blank'
      expect(feedback_link['rel']).to eq 'noopener noreferrer'
    end

    it 'displays SUL footer' do
      expect(page).to have_css('#sul-footer #sul-footer-img img')
      expect(page).to have_css('#sul-footer-links a', text: 'Hours & locations')
      expect(page).to have_css('#sul-footer-links a', text: 'My Account')
      expect(page).to have_css('#sul-footer-links a', text: 'Ask us')
      expect(page).to have_css('#sul-footer-links a', text: 'Opt out of analytics')
    end

    it 'displays SU footer' do
      expect(page).to have_css('#global-footer #bottom-logo img')
      expect(page).to have_css('#global-footer #bottom-text a', text: 'Stanford Home')
      expect(page).to have_css('#global-footer #bottom-text a', text: 'Maps & Directions')
      expect(page).to have_css('#global-footer #bottom-text a', text: 'Search Stanford')
      expect(page).to have_css('#global-footer #bottom-text a', text: 'Terms of Use')
      expect(page).to have_css('#global-footer #bottom-text a', text: 'Emergency Info')
    end
  end

  describe 'mediation section' do
    before do
      create(:mediated_page)
      create(:page_mp_mediated_page)
      stub_current_user(create(:superadmin_user))
      visit root_path
    end

    it 'has links for the library level mediation' do
      expect(page).to have_link('Art & Architecture Library (Bowes)', href: '/admin/ART')
    end

    it 'has links for the location level mediation' do
      expect(page).to have_link('Earth Sciences Library (Branner)', href: '/admin/PAGE-MP')
    end
  end
end
